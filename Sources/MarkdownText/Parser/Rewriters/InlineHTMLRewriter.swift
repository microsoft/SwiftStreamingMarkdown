//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Markdown

/// Rewrites supported inline raw-HTML tags into their Markdown equivalents so
/// they render instead of being dropped by inline conversion.
///
/// Supported mappings:
/// - `<br>` / `<br/>` → line break, `<wbr>` → zero-width space
/// - `<b>` / `<strong>` → strong, `<i>` / `<em>` → emphasis
/// - `<s>` / `<del>` / `<strike>` → strikethrough
/// - `<u>` / `<ins>` → underline, `<mark>` → highlight
/// - `<sub>` / `<sup>` → sub/superscript
/// - `<code>` / `<kbd>` / `<samp>` / `<tt>` → inline code
/// - `<a href="…">` → link
///
/// Comments are dropped. Unsupported or unmatched tags render as literal text
/// so their source stays visible. An open tag with no matching close applies
/// to the rest of the inline container (browser-style auto-close), which keeps
/// streamed documents sensible while a tag is still arriving.
///
/// Standalone-line tags are parsed by cmark as `HTMLBlock` rather than
/// `InlineHTML`; those blocks are converted to literal paragraphs so their
/// text is never silently dropped.
final class InlineHTMLRewriter: MarkupRewriter {

  /// Maximum tag-pair nesting depth processed before the remainder of a
  /// container is emitted literally. Bounds recursion and the per-open
  /// closing-tag scan on adversarial inputs like thousands of unclosed tags.
  private static let maxDepth = 64

  private enum Tag {
    case open(name: String, attributes: String)
    case close(name: String)
    case comment
    case other
  }

  private static let pairedTags: Set<String> = [
    "b", "strong", "i", "em", "s", "del", "strike",
    "u", "ins", "mark", "sub", "sup",
    "code", "kbd", "samp", "tt", "a"
  ]

  /// Whitespace cmark accepts inside a tag (`spacechar` in the HTML scanners).
  private static let htmlWhitespace: Set<Character> = [" ", "\t", "\n", "\r", "\u{0B}", "\u{0C}"]

  /// `HTMLBlock` nodes have no renderable representation; without this they
  /// would be dropped, losing their text entirely. Render the source verbatim
  /// so `<details>` and friends degrade to readable text. Comments,
  /// processing instructions, and declarations are dropped like their inline
  /// counterparts rather than surfacing as visible text.
  func visitHTMLBlock(_ htmlBlock: HTMLBlock) -> Markup? {
    let raw = htmlBlock.rawHTML.trimmingCharacters(in: .whitespacesAndNewlines)
    if raw.hasPrefix("<!--") || raw.hasPrefix("<?") || raw.hasPrefix("<!") {
      return nil
    }
    return Paragraph([Text(htmlBlock.rawHTML)])
  }

  func visitParagraph(_ paragraph: Paragraph) -> Markup? { rewriteInlineChildren(paragraph) }
  func visitHeading(_ heading: Heading) -> Markup? { rewriteInlineChildren(heading) }
  func visitTableCell(_ tableCell: Table.Cell) -> Markup? { rewriteInlineChildren(tableCell) }
  func visitEmphasis(_ emphasis: Emphasis) -> Markup? { rewriteInlineChildren(emphasis) }
  func visitStrong(_ strong: Strong) -> Markup? { rewriteInlineChildren(strong) }
  func visitStrikethrough(_ strikethrough: Strikethrough) -> Markup? { rewriteInlineChildren(strikethrough) }
  func visitLink(_ link: Link) -> Markup? { rewriteInlineChildren(link) }
  func visitInlineAttributes(_ attributes: InlineAttributes) -> Markup? { rewriteInlineChildren(attributes) }
  func visitImage(_ image: Image) -> Markup? { rewriteInlineChildren(image) }

  /// Recursively visits the container's children first, then rewrites the tag
  /// sequences at this level. Containers without `InlineHTML` are returned
  /// unchanged so untouched subtrees keep their identity.
  private func rewriteInlineChildren<Container: InlineContainer & Markup>(_ container: Container) -> Markup? {
    guard Self.containsInlineHTML(container) else { return container }
    // `defaultVisit` is `mutating` on the non-class-bound visitor protocol, so
    // it must be called through a variable; `self` is a class reference here.
    var mutableSelf = self
    guard var visited = mutableSelf.defaultVisit(container) as? Container else { return container }
    var children = process(Array(visited.children))
    // `Link`, `Image`, and `InlineAttributes` only allow `RecurringInlineMarkup`
    // children; degraded nodes keep their text as a literal fallback.
    if visited is Link || visited is Image || visited is InlineAttributes {
      children = children.map { $0 as? (any RecurringInlineMarkup) ?? Text($0.plainText) }
    }
    visited.setInlineChildren(children)
    return visited
  }

  /// Whether the subtree contains any `InlineHTML` or `HTMLBlock` node. Used
  /// to prune containers (and whole documents) that need no rewriting.
  static func containsInlineHTML(_ markup: Markup) -> Bool {
    markup.children.contains {
      $0 is InlineHTML || $0 is HTMLBlock || containsInlineHTML($0)
    }
  }

  private func process(_ input: [Markup], depth: Int = 0) -> [InlineMarkup] {
    // At the depth cap, emit everything verbatim: `InlineHTML` becomes literal
    // text and other nodes pass through. This bounds recursion and the
    // per-open scan on inputs like thousands of unclosed `<b>` tags.
    if depth >= Self.maxDepth {
      return input.compactMap { markup in
        guard let html = markup as? InlineHTML else { return markup as? InlineMarkup }
        if case .comment = classify(html) { return nil }
        return Text(html.rawHTML)
      }
    }
    var output: [InlineMarkup] = []
    var index = 0
    while index < input.count {
      guard let html = input[index] as? InlineHTML else {
        if let markup = input[index] as? InlineMarkup {
          output.append(markup)
        }
        index += 1
        continue
      }
      switch classify(html) {
      case .comment:
        index += 1
      case .close("br"):
        // `</br>` is a parse error that browsers treat as `<br>`.
        output.append(LineBreak())
        index += 1
      case .other, .close:
        output.append(Text(html.rawHTML))
        index += 1
      case .open(let name, let attributes):
        if name == "br" {
          output.append(LineBreak())
          index += 1
          continue
        }
        if name == "wbr" {
          output.append(Text("\u{200B}"))
          index += 1
          continue
        }
        guard Self.pairedTags.contains(name) else {
          output.append(Text(html.rawHTML))
          index += 1
          continue
        }
        if let closeIndex = findClosingIndex(named: name, in: input, from: index + 1) {
          let inner = process(Array(input[(index + 1)..<closeIndex]), depth: depth + 1)
          output.append(contentsOf: wrapOrLiteral(open: html, close: input[closeIndex], name: name, attributes: attributes, inner: inner))
          index = closeIndex + 1
        } else {
          let inner = process(Array(input[(index + 1)...]), depth: depth + 1)
          output.append(contentsOf: wrapOrLiteral(open: html, close: nil, name: name, attributes: attributes, inner: inner))
          index = input.count
        }
      }
    }
    return output
  }

  /// Returns the wrapped pair, or the literal open tag + inner nodes + literal
  /// close tag when the pair can't be represented.
  private func wrapOrLiteral(open: InlineHTML, close: Markup?, name: String, attributes: String, inner: [InlineMarkup]) -> [InlineMarkup] {
    if let wrapped = wrapPair(name: name, attributes: attributes, inner: inner) {
      return wrapped
    }
    var literal: [InlineMarkup] = [Text(open.rawHTML)]
    literal.append(contentsOf: inner)
    if let close = close as? InlineHTML {
      literal.append(Text(close.rawHTML))
    }
    return literal
  }

  private func classify(_ html: InlineHTML) -> Tag {
    let raw = html.rawHTML.trimmingCharacters(in: .whitespaces)
    if raw.hasPrefix("<!--") { return .comment }
    guard raw.count > 2, raw.hasPrefix("<"), raw.hasSuffix(">") else { return .other }
    var inner = String(raw.dropFirst().dropLast())
    if inner.hasPrefix("/") {
      inner.removeFirst()
      let name = inner.split(whereSeparator: { Self.htmlWhitespace.contains($0) || $0 == "/" }).first.map(String.init) ?? ""
      return name.first?.isLetter == true ? .close(name: name.lowercased()) : .other
    }
    // A trailing "/" does not close non-void elements in HTML5, so `<b/>x`
    // behaves like `<b>x`; the tag is still treated as an open.
    if inner.hasSuffix("/") { inner = String(inner.dropLast()) }
    guard let nameEnd = inner.firstIndex(where: { Self.htmlWhitespace.contains($0) }) else {
      let name = inner.lowercased()
      return name.first?.isLetter == true ? .open(name: name, attributes: "") : .other
    }
    let name = String(inner[..<nameEnd]).lowercased()
    guard name.first?.isLetter == true else { return .other }
    return .open(name: name, attributes: String(inner[nameEnd...]))
  }

  /// Finds the matching `</name>` for an open tag at `start - 1`, counting
  /// nested same-name tags. Other tags do not affect depth, matching how
  /// browsers auto-close interleaved markup (the stray closer then renders
  /// literally at the outer level).
  private func findClosingIndex(named name: String, in input: [Markup], from start: Int) -> Int? {
    var depth = 0
    for index in start..<input.count {
      guard let html = input[index] as? InlineHTML else { continue }
      switch classify(html) {
      case .open(let tagName, _) where tagName == name:
        depth += 1
      case .close(let tagName) where tagName == name:
        if depth == 0 { return index }
        depth -= 1
      default:
        continue
      }
    }
    return nil
  }

  /// Wraps the processed children of a matched tag pair, or returns `nil` when
  /// the pair cannot be represented (the caller then renders it literally).
  private func wrapPair(name: String, attributes: String, inner: [InlineMarkup]) -> [InlineMarkup]? {
    switch name {
    case "b", "strong":
      return splitOnImages(inner) { Strong($0) }
    case "i", "em":
      return splitOnImages(inner) { Emphasis($0) }
    case "s", "del", "strike":
      return splitOnImages(inner) { Strikethrough($0) }
    case "u", "ins":
      return attributeWrap("underline", inner)
    case "mark":
      return attributeWrap("highlight", inner)
    case "sub":
      return attributeWrap("subscript", inner)
    case "sup":
      return attributeWrap("superscript", inner)
    case "code", "kbd", "samp", "tt":
      return [InlineCode(inner.map { ($0 as? InlineCode)?.code ?? $0.plainText }.joined())]
    case "a":
      guard let href = hrefValue(in: attributes),
            let children = linkChildren(inner) else { return nil }
      return [Link(destination: href, children)]
    default:
      return nil
    }
  }

  /// Splits a basic wrapper run around `Image` children: images must reach
  /// paragraph level for `ImageBlockRewriter` to hoist them into blocks —
  /// an `Image` nested inside `Strong` would be dropped at conversion.
  private func splitOnImages(_ inner: [InlineMarkup], wrap: ([InlineMarkup]) -> InlineMarkup) -> [InlineMarkup] {
    var output: [InlineMarkup] = []
    var run: [InlineMarkup] = []
    for markup in inner {
      if markup is Image {
        if !run.isEmpty {
          output.append(wrap(run))
          run = []
        }
        output.append(markup)
      } else {
        run.append(markup)
      }
    }
    if !run.isEmpty { output.append(wrap(run)) }
    return output
  }

  /// `InlineAttributes` children must be `RecurringInlineMarkup`. Stacked
  /// attribute tags (`<u><sup>x</sup></u>`) merge into a single node; other
  /// non-recurring children (`Link`, `Image`) split the attribute run so the
  /// surrounding text still gets the style instead of the whole pair going
  /// literal.
  private func attributeWrap(_ key: String, _ inner: [InlineMarkup]) -> [InlineMarkup] {
    var output: [InlineMarkup] = []
    var run: [any RecurringInlineMarkup] = []

    func flushRun() {
      guard !run.isEmpty else { return }
      output.append(InlineAttributes(attributes: "{\(key):true}", run))
      run = []
    }

    for markup in inner {
      if let attributes = markup as? InlineAttributes {
        // Nested attribute tags merge keys: `<u><sup>x</sup></u>` keeps both
        // underline and superscript. Children that can't rebuild the node
        // degrade to the unmerged original.
        flushRun()
        if let children = recurring(Array(attributes.children)) {
          output.append(InlineAttributes(attributes: mergedAttributes(attributes.attributes, key: key), children))
        } else {
          output.append(attributes)
        }
      } else if let recurring = markup as? (any RecurringInlineMarkup) {
        run.append(recurring)
      } else {
        // Non-recurring nodes (`Link`, `Image`) end the run but stay in the
        // output, so `<u>text <a>x</a> more</u>` underlines both text parts.
        flushRun()
        output.append(markup)
      }
    }
    flushRun()
    return output
  }

  /// Attributes produced by this rewriter always end in `}`; attribute nodes
  /// from other sources keep their original string, dropping the new key —
  /// graceful degradation rather than a malformed merge.
  private func mergedAttributes(_ attributes: String, key: String) -> String {
    guard attributes.hasSuffix("}") else { return attributes }
    return String(attributes.dropLast()) + ",\(key):true}"
  }

  /// `Link` children must be `RecurringInlineMarkup`; `InlineAttributes` nodes
  /// inside an anchor are flattened to their children (the link wins over the
  /// inner styling, which is the more useful behavior).
  private func linkChildren(_ inner: [InlineMarkup]) -> [any RecurringInlineMarkup]? {
    var children: [any RecurringInlineMarkup] = []
    for markup in inner {
      if let attributes = markup as? InlineAttributes {
        guard let nested = recurring(Array(attributes.children)) else { return nil }
        children.append(contentsOf: nested)
      } else if let recurring = markup as? (any RecurringInlineMarkup) {
        children.append(recurring)
      } else {
        return nil
      }
    }
    return children
  }

  private func recurring(_ inner: [Markup]) -> [any RecurringInlineMarkup]? {
    let children = inner.compactMap { $0 as? (any RecurringInlineMarkup) }
    return children.count == inner.count ? children : nil
  }

  /// Extracts the `href` value from a tag's attribute string with a
  /// quote-aware scan: attribute names are matched case-insensitively on a
  /// whitespace boundary, and quoted values are skipped rather than scanned,
  /// so `data-href` or `title="a href='b'"` can't produce a link.
  private func hrefValue(in attributes: String) -> String? {
    var index = attributes.startIndex
    var previousWasBoundary = true
    while index < attributes.endIndex {
      let character = attributes[index]
      if character == "\"" || character == "'" {
        // Skip a quoted attribute value entirely.
        index = attributes[index...].dropFirst().firstIndex(of: character) ?? attributes.endIndex
        if index < attributes.endIndex { index = attributes.index(after: index) }
        previousWasBoundary = false
        continue
      }
      defer { index = attributes.index(after: index) }
      if character == "h" || character == "H", previousWasBoundary {
        let rest = attributes[index...]
        if rest.prefix(4).lowercased() == "href" {
          var cursor = rest.index(rest.startIndex, offsetBy: 4)
          while cursor < attributes.endIndex, Self.htmlWhitespace.contains(attributes[cursor]) {
            cursor = attributes.index(after: cursor)
          }
          if cursor < attributes.endIndex, attributes[cursor] == "=" {
            cursor = attributes.index(after: cursor)
            while cursor < attributes.endIndex, Self.htmlWhitespace.contains(attributes[cursor]) {
              cursor = attributes.index(after: cursor)
            }
            return decodeEntities(attributeValue(in: attributes, from: &cursor))
          }
        }
      }
      previousWasBoundary = Self.htmlWhitespace.contains(character)
    }
    return nil
  }

  /// Reads one attribute value: quoted, or unquoted until whitespace/`>`.
  private func attributeValue(in attributes: String, from cursor: inout String.Index) -> String {
    guard cursor < attributes.endIndex else { return "" }
    let quote = attributes[cursor]
    if quote == "\"" || quote == "'" {
      let valueStart = attributes.index(after: cursor)
      let valueEnd = attributes[valueStart...].firstIndex(of: quote) ?? attributes.endIndex
      cursor = valueEnd < attributes.endIndex ? attributes.index(after: valueEnd) : attributes.endIndex
      return String(attributes[valueStart..<valueEnd])
    }
    var end = cursor
    while end < attributes.endIndex, !Self.htmlWhitespace.contains(attributes[end]), attributes[end] != ">" {
      end = attributes.index(after: end)
    }
    defer { cursor = end }
    return String(attributes[cursor..<end])
  }

  /// Decodes the common named and numeric entities found in attribute values
  /// (cmark decodes `Text` nodes but never sees attribute contents).
  private func decodeEntities(_ value: String) -> String {
    guard value.contains("&") else { return value }
    var result = value
    result = result.replacingOccurrences(of: "&quot;", with: "\"")
    result = result.replacingOccurrences(of: "&#39;", with: "'")
    result = result.replacingOccurrences(of: "&#x27;", with: "'")
    result = result.replacingOccurrences(of: "&lt;", with: "<")
    result = result.replacingOccurrences(of: "&gt;", with: ">")
    result = result.replacingOccurrences(of: "&amp;", with: "&")
    return result
  }
}
