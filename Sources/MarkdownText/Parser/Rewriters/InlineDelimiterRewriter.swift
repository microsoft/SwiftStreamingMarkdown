//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Markdown

/// Rewrites paired inline delimiter runs into `InlineAttributes` nodes so
/// syntax like `==highlight==` renders instead of staying literal text.
///
/// Each `DelimiterSpec` describes one marker. `Text` content is scanned for
/// maximal runs of the marker's character; a run of length `n` yields
/// `n % marker.count` literal characters followed by `n / marker.count`
/// marker tokens, so `===x===` produces `=` + marker + `x` + marker + `=`.
///
/// All markers in a run share the run's flanking: a marker can open when a
/// non-whitespace character follows the run and can close when a
/// non-whitespace character precedes it. Scanning left to right with an
/// opener stack pairs each closer with the most recent unmatched opener, so
/// `====x====` nests and still highlights `x`. Markers that never pair stay
/// as literal text, which keeps streamed documents sensible while a closing
/// delimiter is still arriving.
///
/// `Link`, `Image`, and `InlineAttributes` containers are visited but never
/// paired at their own level: their children must stay
/// `RecurringInlineMarkup`, so `==` there remains literal. Nested containers
/// inside them still pair — `[*==x==*](u)` renders highlighted italic link
/// text.
///
/// Backslash escapes and entities (`\==`, `\^`, `&#94;`) stay literal: cmark
/// merges decoded characters into the surrounding `Text` node, and `tokenize`
/// detects the mismatch between the node's source span and its decoded
/// contents so escaped markers are never consumed.
final class InlineDelimiterRewriter: MarkupRewriter {

  /// Describes one inline delimiter pair and the attribute it produces.
  struct DelimiterSpec {
    /// The repeated-character marker text, e.g. `"=="`. `tokenize` assumes a
    /// single repeated character (`run % marker.count`) and matches specs by
    /// `marker.first`, so markers must be one repeated character and distinct
    /// in their first character across specs.
    let marker: String
    /// The `InlineAttributes` key set to `true` on wrapped content.
    let attribute: String
    /// Whether the wrapped range may contain whitespace. `false` keeps the
    /// markers of a pair like `^a b^` literal.
    let allowsInnerWhitespace: Bool

    init(marker: String, attribute: String, allowsInnerWhitespace: Bool) {
      precondition(!marker.isEmpty && marker.allSatisfy { $0 == marker.first })
      self.marker = marker
      self.attribute = attribute
      self.allowsInnerWhitespace = allowsInnerWhitespace
    }

    /// `==highlight==`; inner whitespace is allowed.
    static let highlight = DelimiterSpec(marker: "==", attribute: "highlight", allowsInnerWhitespace: true)
  }

  /// Maximum nested-pair depth transformed before markers are emitted
  /// literally. Bounds recursion on adversarial inputs like hundreds of
  /// nested `====...====` runs.
  private static let maxDepth = 64

  private let specs: [DelimiterSpec]

  init(specs: [DelimiterSpec]) {
    // Specs are matched by `marker.first`, so a shared first character would
    // make the later spec unreachable.
    precondition(Set(specs.map { $0.marker.first }).count == specs.count)
    self.specs = specs
  }

  func visitParagraph(_ paragraph: Paragraph) -> Markup? { rewriteInlineChildren(paragraph) }
  func visitHeading(_ heading: Heading) -> Markup? { rewriteInlineChildren(heading) }
  func visitTableCell(_ tableCell: Table.Cell) -> Markup? { rewriteInlineChildren(tableCell) }
  func visitEmphasis(_ emphasis: Emphasis) -> Markup? { rewriteInlineChildren(emphasis) }
  func visitStrong(_ strong: Strong) -> Markup? { rewriteInlineChildren(strong) }
  func visitStrikethrough(_ strikethrough: Strikethrough) -> Markup? { rewriteInlineChildren(strikethrough) }
  func visitLink(_ link: Link) -> Markup? { rewriteInlineChildren(link) }
  func visitImage(_ image: Image) -> Markup? { rewriteInlineChildren(image) }
  func visitInlineAttributes(_ attributes: InlineAttributes) -> Markup? { rewriteInlineChildren(attributes) }

  /// A flattened sibling: a literal text fragment, a run remainder that is
  /// also literal text but carries provenance for flanking and wrap
  /// boundaries, an opaque non-`Text` node, or one delimiter marker token
  /// stamped with its run's flanking.
  private enum Piece {
    case text(String)
    case remainder(String)
    case node(InlineMarkup)
    case marker(specIndex: Int, canOpen: Bool, canClose: Bool)
  }

  /// Recursively visits the container's children first, then pairs delimiter
  /// markers at this level. Containers without a spec marker in any `Text`
  /// descendant are returned unchanged so untouched subtrees keep identity.
  private func rewriteInlineChildren<Container: InlineContainer & Markup>(_ container: Container) -> Markup? {
    guard Self.containsDelimiter(container, specs: specs) else { return container }
    // `defaultVisit` is `mutating` on the non-class-bound visitor protocol, so
    // it must be called through a variable; `self` is a class reference here.
    var mutableSelf = self
    guard var visited = mutableSelf.defaultVisit(container) as? Container else { return container }
    // `Link`, `Image`, and `InlineAttributes` only allow `RecurringInlineMarkup`
    // children, so markers at their level are never consumed; deeper
    // containers have already been processed by `defaultVisit`.
    if visited is Link || visited is Image || visited is InlineAttributes {
      return visited
    }
    visited.setInlineChildren(process(
      Array(visited.children),
      allowsImagePassthrough: (visited as? Paragraph)?.parent is Document
    ))
    return visited
  }

  /// Whether the subtree contains a `Text` node holding a spec marker. Used
  /// to prune containers (and whole documents) that need no rewriting.
  static func containsDelimiter(_ markup: Markup, specs: [DelimiterSpec]) -> Bool {
    markup.children.contains { child in
      if let text = child as? Text, specs.contains(where: { text.string.contains($0.marker) }) {
        return true
      }
      return containsDelimiter(child, specs: specs)
    }
  }

  /// Pairs the container's direct children. `allowsImagePassthrough` is
  /// true only for top-level paragraphs — the only place
  /// `ImageBlockRewriter` can hoist an `Image` out of a wrap; inside deeper
  /// containers the node would be dropped at conversion, so it degrades to
  /// text instead. When no marker pair exists the input passes through
  /// unchanged so untouched subtrees keep identity.
  private func process(_ input: [Markup], allowsImagePassthrough: Bool) -> [InlineMarkup] {
    var pieces = tokenize(input)
    applyFlanking(&pieces)
    let closeForOpen = pairedCloses(in: pieces)
    guard !closeForOpen.isEmpty else {
      return input.compactMap { $0 as? InlineMarkup }
    }
    return emit(pieces, in: 0..<pieces.count, closeForOpen: closeForOpen, depth: 0,
                allowsImagePassthrough: allowsImagePassthrough)
  }

  /// Splits sibling inline nodes into pieces. `Text` runs of a marker
  /// character become a `remainder` of `n % marker.count` characters plus
  /// `n / marker.count` marker tokens; every other node stays opaque.
  private func tokenize(_ input: [Markup]) -> [Piece] {
    var pieces: [Piece] = []
    for child in input {
      guard let text = child as? Text else {
        if let inline = child as? InlineMarkup {
          pieces.append(.node(inline))
        } else {
          pieces.append(.text((child as? PlainTextConvertibleMarkup)?.plainText ?? ""))
        }
        continue
      }
      let string = text.string
      // A `Text` node whose source span is wider than its decoded contents
      // holds escapes or entities (`\==`, `&#94;`, `\\`): cmark merges them
      // with plain text, so which characters were escaped can't be told
      // apart without the source. The whole node stays literal rather than
      // consuming escaped markers; source columns count UTF-8 bytes.
      if let range = text.range,
         range.lowerBound.line != range.upperBound.line
           || range.upperBound.column - range.lowerBound.column != string.utf8.count {
        pieces.append(.text(string))
        continue
      }
      var index = string.startIndex
      var literalStart = index
      while index < string.endIndex {
        guard let specIndex = specs.firstIndex(where: { $0.marker.first == string[index] }) else {
          index = string.index(after: index)
          continue
        }
        var runEnd = string.index(after: index)
        while runEnd < string.endIndex, string[runEnd] == string[index] {
          runEnd = string.index(after: runEnd)
        }
        if literalStart < index {
          pieces.append(.text(String(string[literalStart..<index])))
        }
        let runLength = string.distance(from: index, to: runEnd)
        let markerLength = specs[specIndex].marker.count
        let literalCount = runLength % markerLength
        if literalCount > 0 {
          pieces.append(.remainder(String(repeating: string[index], count: literalCount)))
        }
        for _ in 0..<(runLength / markerLength) {
          pieces.append(.marker(specIndex: specIndex, canOpen: false, canClose: false))
        }
        index = runEnd
        literalStart = runEnd
      }
      if literalStart < string.endIndex {
        pieces.append(.text(String(string[literalStart...])))
      }
    }
    return pieces
  }

  /// Computes flanking once per marker run and stamps it onto every token.
  /// A run's `canOpen` requires a non-whitespace character after the last
  /// marker; `canClose` requires a non-whitespace character before the run,
  /// which sits before any `remainder` the run emitted.
  private func applyFlanking(_ pieces: inout [Piece]) {
    var index = 0
    while index < pieces.count {
      guard case .marker = pieces[index] else {
        index += 1
        continue
      }
      var runEnd = index + 1
      // Adjacent markers of any spec share one flanking run — a deliberate
      // divergence from markdown-it, which computes flanking per marker
      // type. Sharing the run is what lets `^==x==^`-style mixed nesting
      // pair correctly at both levels.
      while runEnd < pieces.count, case .marker = pieces[runEnd] {
        runEnd += 1
      }
      var runStart = index
      guard case .marker(let runSpecIndex, _, _) = pieces[index] else {
        index += 1
        continue
      }
      while runStart > 0, case .remainder(let string) = pieces[runStart - 1],
            specs[runSpecIndex].marker.contains(string) {
        runStart -= 1
      }
      let previous = runStart > 0 ? lastCharacter(of: pieces[runStart - 1]) : nil
      let next = runEnd < pieces.count ? firstCharacter(of: pieces[runEnd]) : nil
      let lastWS = previous?.isWhitespace ?? false
      let lastPunct = previous.map(Self.isDelimiterPunctuation) ?? false
      let nextWS = next?.isWhitespace ?? false
      let nextPunct = next.map(Self.isDelimiterPunctuation) ?? false
      // markdown-it's left/right-flanking rules; checking whitespace alone
      // would pair `a==(b)==c`, which the reference renderer keeps literal.
      let canClose = !lastWS && (!lastPunct || nextWS || nextPunct)
      let canOpen = !nextWS && (!nextPunct || lastWS || lastPunct)
      for markerIndex in index..<runEnd {
        guard case .marker(let specIndex, _, _) = pieces[markerIndex] else { continue }
        pieces[markerIndex] = .marker(specIndex: specIndex, canOpen: canOpen, canClose: canClose)
      }
      index = runEnd
    }
  }

  /// Pairs each closer with the most recent unmatched opener of the same
  /// spec and returns `open index -> close index`. A marker that can both
  /// open and close prefers closing when an opener exists, except an
  /// immediately adjacent one: markdown-it's jump rule keeps `====x====`
  /// pairing outer-to-inner instead of collapsing each run's two markers
  /// onto each other with nothing between them.
  private func pairedCloses(in pieces: [Piece]) -> [Int: Int] {
    var openers: [[Int]] = specs.map { _ in [] }
    var closeForOpen: [Int: Int] = [:]
    for (index, piece) in pieces.enumerated() {
      guard case .marker(let specIndex, let canOpen, let canClose) = piece else { continue }
      if canClose, let openIndex = openers[specIndex].last, index - openIndex > 1 {
        openers[specIndex].removeLast()
        closeForOpen[openIndex] = index
      } else if canOpen {
        openers[specIndex].append(index)
      }
    }
    return closeForOpen
  }

  /// Emits the piece range, wrapping each paired open/close span in an
  /// `InlineAttributes` node. Pairs nest, so an outer wrap absorbs an inner
  /// `InlineAttributes` as plain text; unpaired markers become literal text.
  private func emit(_ pieces: [Piece], in range: Range<Int>, closeForOpen: [Int: Int], depth: Int,
                    allowsImagePassthrough: Bool) -> [InlineMarkup] {
    var output: [InlineMarkup] = []
    var index = range.lowerBound
    while index < range.upperBound {
      switch pieces[index] {
      case .text(let string), .remainder(let string):
        output.append(Text(string))
        index += 1
      case .node(let node):
        output.append(node)
        index += 1
      case .marker(let specIndex, _, _):
        let spec = specs[specIndex]
        // `close < range.upperBound` keeps cross-spec pairs from escaping
        // the enclosing wrap's range: per-spec opener stacks can produce a
        // pair whose closer lies outside an inner emit, which would emit
        // the enclosing pieces twice. Crossing markers stay literal and the
        // outer pair wins.
        guard let close = closeForOpen[index], close < range.upperBound, depth < Self.maxDepth else {
          output.append(Text(spec.marker))
          index += 1
          continue
        }
        // `remainder` pieces at the wrap boundary belong to the consumed
        // markers' own runs, so they emit outside: `===x===` highlights `x`
        // and leaves one literal `=` on each side. A remainder whose char
        // differs from the spec's marker is foreign interior content and
        // stays inside the range (`=^` remainders never belong to a `^`
        // run, which can't produce remainders at all).
        var innerStart = index + 1
        var innerEnd = close
        var leading: [String] = []
        while innerStart < innerEnd, case .remainder(let string) = pieces[innerStart],
              spec.marker.contains(string) {
          leading.append(string)
          innerStart += 1
        }
        var trailing: [String] = []
        while innerEnd > innerStart, case .remainder(let string) = pieces[innerEnd - 1],
              spec.marker.contains(string) {
          trailing.insert(string, at: 0)
          innerEnd -= 1
        }
        let inner = emit(pieces, in: innerStart..<innerEnd, closeForOpen: closeForOpen, depth: depth + 1,
                         allowsImagePassthrough: allowsImagePassthrough)
        // An empty inner range (`a====b`) means the markers delimit nothing;
        // emit in piece order so nothing is lost or reordered.
        guard !inner.isEmpty else {
          output.append(Text(spec.marker))
          output.append(contentsOf: leading.map { Text($0) })
          output.append(contentsOf: trailing.map { Text($0) })
          output.append(Text(spec.marker))
          index = close + 1
          continue
        }
        let containsWhitespace = !spec.allowsInnerWhitespace && inner.contains { markup in
          markup.plainText.contains { $0.isWhitespace }
        }
        if spec.allowsInnerWhitespace || !containsWhitespace {
          output.append(contentsOf: leading.map { Text($0) })
          output.append(contentsOf: attributeWrap("\(spec.attribute):true", inner,
                                                  allowsImagePassthrough: allowsImagePassthrough))
          output.append(contentsOf: trailing.map { Text($0) })
        } else {
          // Rejected pairs emit literally in piece order.
          output.append(Text(spec.marker))
          output.append(contentsOf: leading.map { Text($0) })
          output.append(contentsOf: inner)
          output.append(contentsOf: trailing.map { Text($0) })
          output.append(Text(spec.marker))
        }
        index = close + 1
      }
    }
    return output
  }

  /// `InlineAttributes` children must be `RecurringInlineMarkup`, so a
  /// generated wrap cannot contain a nested `InlineAttributes` node. Runs
  /// around nested attribute nodes are split instead: each nested node's
  /// children are re-wrapped under the union of both key sets, which keeps
  /// e.g. `==a <sup>b</sup>==` as highlighted text with a superscripted `b`
  /// rather than dropping the inner style. `Link` and paragraph-level
  /// `Image` children end the current run and pass through unstyled but
  /// alive; other non-recurring nodes (`SymbolLink`, or `Image` inside a
  /// deeper container that can't hoist it) degrade to their text fallback
  /// so they join the styled run instead of vanishing at conversion.
  private func attributeWrap(_ key: String, _ inner: [InlineMarkup],
                             allowsImagePassthrough: Bool) -> [InlineMarkup] {
    var output: [InlineMarkup] = []
    var run: [any RecurringInlineMarkup] = []

    func flushRun() {
      guard !run.isEmpty else { return }
      output.append(InlineAttributes(attributes: "{\(key)}", run))
      run = []
    }

    for markup in inner {
      if let attributes = markup as? InlineAttributes {
        flushRun()
        if let mergedKey = mergedKeys(key, inner: attributes.attributes) {
          output.append(contentsOf: attributeWrap(mergedKey, attributes.children.compactMap { $0 as? InlineMarkup },
                                                  allowsImagePassthrough: allowsImagePassthrough))
        } else {
          output.append(attributes)
        }
      } else if let recurring = markup as? (any RecurringInlineMarkup) {
        run.append(recurring)
      } else if markup is any InlineConvertible || (markup is Image && allowsImagePassthrough) {
        // `Link` and other convertible nodes stay in the output between
        // styled runs; a paragraph-level `Image` stays a node so
        // `ImageBlockRewriter` can hoist it.
        flushRun()
        output.append(markup)
      } else {
        // An `Image` deeper than paragraph level or a `SymbolLink` would
        // be silently dropped at conversion; degrade to its text fallback
        // so `**==a ![i](s) b==**` keeps "i" inside the styled run.
        run.append(Text(markup.plainText))
      }
    }
    flushRun()
    return output
  }

  /// Keys like `subscript:true` the renderer understands. Attribute nodes
  /// generated by this rewriter and `InlineHTMLRewriter` always match;
  /// anything else keeps its original attributes.
  private static let enabledKeyRegex = try? Regex(#"(?:^|[,{}\s])([a-zA-Z]+)\s*:\s*true\b"#)

  /// Union of `base` and the inner node's keys (`"a:true"` comma-separated
  /// contents without braces). Returns `nil` when the inner attribute string
  /// holds no recognized keys, so the node can pass through unchanged.
  /// Anything the regex doesn't recognize is dropped from the merged result,
  /// so producers must emit `name:true` entries only.
  private func mergedKeys(_ base: String, inner: String) -> String? {
    guard let regex = Self.enabledKeyRegex else { return nil }
    var merged = base
    var found = false
    for match in inner.matches(of: regex) {
      guard let key = match.output[1].substring else { continue }
      let entry = "\(key):true"
      if !merged.split(separator: ",").map(String.init).contains(entry) {
        merged += ",\(entry)"
      }
      found = true
    }
    return found ? merged : nil
  }

  /// ASCII punctuation matching markdown-it's `isPunctChar`
  /// (`Character.isPunctuation` misses symbols like `` ` ``, `~`, `^`, `=`,
  /// and `$`, which markdown-it counts as flanking punctuation).
  private static let punctuationCharacters = Set<Character>(
    "!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~"
  )

  private static func isDelimiterPunctuation(_ character: Character) -> Bool {
    punctuationCharacters.contains(character)
  }

  private func firstCharacter(of piece: Piece) -> Character? {
    switch piece {
    case .text(let string), .remainder(let string):
      return string.first
    case .node(let node):
      return node.plainText.first
    case .marker(let specIndex, _, _):
      return specs[specIndex].marker.first
    }
  }

  private func lastCharacter(of piece: Piece) -> Character? {
    switch piece {
    case .text(let string), .remainder(let string):
      return string.last
    case .node(let node):
      return node.plainText.last
    case .marker(let specIndex, _, _):
      return specs[specIndex].marker.last
    }
  }
}
