//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
import RegexBuilder

/// Pre-process GitHub-flavored footnotes (`[^id]` references and `[^id]: text` definitions).
/// swift-markdown attaches no footnote extension and has no footnote node types, so — like
/// `LaTexPreProcessor` — this is a less heavy-weight approach than forking commonmark-gfm
/// and swift-markdown.
///
/// References are numbered by order of first appearance and replaced with a specially
/// marked inline code span that the inline layer renders as a superscript. Definitions
/// are removed from the source and re-emitted as an ordered list after a thematic break
/// at the end of the document. Content inside fenced code blocks and inline code spans
/// is left untouched.
protocol FootnotePreProcessor {
  func process(input: String) -> String
}

final class FootnotePreProcessorImpl: FootnotePreProcessor {

  static let footnoteID = Reference(Substring.self)
  static let footnoteText = Reference(Substring.self)

  /// A whole line of the form `[^id]: text`, allowing up to three leading spaces
  /// (per CommonMark, four or more make the line an indented code block).
  static let definitionLine = Regex {
    Repeat(0...3) { " " }
    "[^"
    Capture(as: footnoteID) {
      OneOrMore(CharacterClass.anyOf("] \t").inverted)
    }
    "]:"
    ZeroOrMore(.horizontalWhitespace)
    Capture(as: footnoteText) {
      ZeroOrMore(.any)
    }
  }

  /// An inline reference of the form `[^id]`.
  static let reference = Regex {
    "[^"
    Capture(as: footnoteID) {
      OneOrMore(CharacterClass.anyOf("] \t").inverted)
    }
    "]"
  }

  /// Marker wrapped in an inline code span so the reference number survives parsing;
  /// `Markdown.InlineCode` detects the prefix/suffix and renders a superscript.
  static let inlineCodePrefix = "[[fnref:"
  static let inlineCodeSuffix = "]]"

  init() {}

  func process(input: String) -> String {
    guard input.contains("[^") else { return input }

    // Normalize CRLF so per-line matching and fence detection see clean lines.
    let normalizedInput = input.replacingOccurrences(of: "\r\n", with: "\n")
    let (contentLines, definitions) = collectDefinitions(input: normalizedInput)
    guard !definitions.isEmpty else { return input }

    var numbers: [String: Int] = [:]
    let processedLines = contentLines.map { line in
      line.isInsideFence ? line.text : replacingReferences(in: line.text, definitions: definitions, numbers: &numbers)
    }

    var result = processedLines.joined(separator: "\n")
    guard !numbers.isEmpty else { return result }

    while result.hasSuffix("\n") {
      result.removeLast()
    }
    let items = numbers
      .sorted { $0.value < $1.value }
      .map { "\($0.value). \(definitions[$0.key] ?? "")" }
    return result + "\n\n---\n\n" + items.joined(separator: "\n")
  }

  /// An open fenced code block: its delimiter character and opening run length.
  /// Per CommonMark, the closing fence must use the same character with a run
  /// at least as long as the opener.
  private struct Fence {
    let character: Character
    let length: Int
  }

  /// The fence run opening `trimmed`, if any (three or more backticks or tildes).
  private func fenceRun(in trimmed: String) -> Fence? {
    guard let first = trimmed.first, first == "`" || first == "~" else { return nil }
    let length = trimmed.prefix(while: { $0 == first }).count
    guard length >= 3 else { return nil }
    return Fence(character: first, length: length)
  }

  /// Whether `trimmed` closes `fence`: same character, a run at least as long,
  /// and nothing after the run.
  private func isClosing(_ fence: Fence, trimmed: String) -> Bool {
    guard let run = fenceRun(in: trimmed),
          run.character == fence.character,
          run.length >= fence.length
    else {
      return false
    }
    return trimmed.dropFirst(run.length).isEmpty
  }

  /// Walks the input line by line, tracking fenced code blocks, and splits it into
  /// surviving content lines plus the collected `id -> text` definitions.
  private func collectDefinitions(input: String) -> (lines: [(text: String, isInsideFence: Bool)], definitions: [String: String]) {
    var lines: [(text: String, isInsideFence: Bool)] = []
    var definitions: [String: String] = [:]
    var currentFence: Fence?

    for line in input.components(separatedBy: "\n") {
      let trimmed = line.trimmingCharacters(in: .whitespaces)
      if let fence = currentFence {
        lines.append((line, true))
        if isClosing(fence, trimmed: trimmed) {
          currentFence = nil
        }
        continue
      }
      if let fence = fenceRun(in: trimmed) {
        currentFence = fence
        lines.append((line, true))
        continue
      }
      if let match = line.wholeMatch(of: Self.definitionLine) {
        let id = String(match[Self.footnoteID])
        if definitions[id] == nil {
          definitions[id] = String(match[Self.footnoteText])
        }
        continue
      }
      lines.append((line, false))
    }
    return (lines, definitions)
  }

  /// Replaces defined references in a line, skipping inline code spans. Spans
  /// follow CommonMark backtick-run rules: a span opens with a run of N backticks
  /// and closes at the next run of exactly N, so single backticks inside a
  /// double-backtick span stay part of the span.
  private func replacingReferences(in line: String, definitions: [String: String], numbers: inout [String: Int]) -> String {
    guard line.contains("[^") else { return line }

    var output = ""
    var segmentStart = line.startIndex
    var index = line.startIndex

    while index < line.endIndex {
      guard line[index] == "`" else {
        index = line.index(after: index)
        continue
      }
      let runStart = index
      var runEnd = index
      while runEnd < line.endIndex, line[runEnd] == "`" {
        runEnd = line.index(after: runEnd)
      }
      let runLength = line.distance(from: runStart, to: runEnd)
      if let closerStart = findClosingRun(in: line, from: runEnd, length: runLength) {
        output += replacingReferences(inSegment: line[segmentStart..<runStart], definitions: definitions, numbers: &numbers)
        let spanEnd = line.index(closerStart, offsetBy: runLength)
        output += line[runStart..<spanEnd]
        segmentStart = spanEnd
        index = spanEnd
      } else {
        // Unmatched run: literal backticks, keep scanning after them.
        index = runEnd
      }
    }
    output += replacingReferences(inSegment: line[segmentStart...], definitions: definitions, numbers: &numbers)
    return output
  }

  /// The start of the first run of exactly `length` backticks at or after `start`.
  private func findClosingRun(in line: String, from start: String.Index, length: Int) -> String.Index? {
    var index = start
    while index < line.endIndex {
      guard line[index] == "`" else {
        index = line.index(after: index)
        continue
      }
      let runStart = index
      var runEnd = index
      while runEnd < line.endIndex, line[runEnd] == "`" {
        runEnd = line.index(after: runEnd)
      }
      if line.distance(from: runStart, to: runEnd) == length {
        return runStart
      }
      index = runEnd
    }
    return nil
  }

  private func replacingReferences(inSegment segment: Substring, definitions: [String: String], numbers: inout [String: Int]) -> String {
    var output = ""
    var index = segment.startIndex
    for match in segment.matches(of: Self.reference) {
      output += segment[index..<match.range.lowerBound]
      let id = String(match[Self.footnoteID])
      if definitions[id] != nil {
        let number: Int
        if let existing = numbers[id] {
          number = existing
        } else {
          number = numbers.count + 1
          numbers[id] = number
        }
        output += "`\(Self.inlineCodePrefix)\(number)\(Self.inlineCodeSuffix)`"
      } else {
        output += segment[match.range]
      }
      index = match.range.upperBound
    }
    output += segment[index...]
    return output
  }
}
