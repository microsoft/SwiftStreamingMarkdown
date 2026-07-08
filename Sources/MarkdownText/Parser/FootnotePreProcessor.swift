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

  /// A whole line of the form `[^id]: text`.
  static let definitionLine = Regex {
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

  /// A single-backtick inline code span within one line.
  static let inlineCodeSpan = Regex {
    "`"
    OneOrMore(CharacterClass.anyOf("`").inverted)
    "`"
  }

  /// Marker wrapped in an inline code span so the reference number survives parsing;
  /// `Markdown.InlineCode` detects the prefix/suffix and renders a superscript.
  static let inlineCodePrefix = "[[fnref:"
  static let inlineCodeSuffix = "]]"

  init() {}

  func process(input: String) -> String {
    guard input.contains("[^") else { return input }

    let (contentLines, definitions) = collectDefinitions(input: input)
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

  /// Walks the input line by line, tracking fenced code blocks, and splits it into
  /// surviving content lines plus the collected `id -> text` definitions.
  private func collectDefinitions(input: String) -> (lines: [(text: String, isInsideFence: Bool)], definitions: [String: String]) {
    var lines: [(text: String, isInsideFence: Bool)] = []
    var definitions: [String: String] = [:]
    var currentFence: String?

    for line in input.components(separatedBy: "\n") {
      let trimmed = line.trimmingCharacters(in: .whitespaces)
      if let fence = currentFence {
        lines.append((line, true))
        if trimmed.hasPrefix(fence) {
          currentFence = nil
        }
        continue
      }
      if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
        currentFence = String(trimmed.prefix(3))
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

  /// Replaces defined references in a line, skipping inline code spans.
  private func replacingReferences(in line: String, definitions: [String: String], numbers: inout [String: Int]) -> String {
    guard line.contains("[^") else { return line }

    var output = ""
    var remainder = line[...]
    while let span = remainder.firstMatch(of: Self.inlineCodeSpan) {
      output += replacingReferences(inSegment: remainder[remainder.startIndex..<span.range.lowerBound], definitions: definitions, numbers: &numbers)
      output += remainder[span.range]
      remainder = remainder[span.range.upperBound...]
    }
    output += replacingReferences(inSegment: remainder, definitions: definitions, numbers: &numbers)
    return output
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
