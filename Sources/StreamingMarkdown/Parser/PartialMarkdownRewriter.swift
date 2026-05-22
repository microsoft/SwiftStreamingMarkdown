import Foundation

public struct PartialMarkdownRewrite: Equatable {
    public let text: String
    public let name: String

    public init(text: String, name: String) {
        self.text = text
        self.name = name
    }
}

public protocol PartialMarkdownRewriter {
    var name: String { get }
    func rewriteIfNeeded(_ text: String) -> PartialMarkdownRewrite?
}

public struct PartialEmphasisRewriter: PartialMarkdownRewriter {
    public let name = "partial-emphasis"

    public init() {}

    public func rewriteIfNeeded(_ text: String) -> PartialMarkdownRewrite? {
        guard let closingToken = closingToken(for: text) else { return nil }
        return PartialMarkdownRewrite(text: text + closingToken, name: name)
    }

    private func closingToken(for text: String) -> String? {
        let searchableText = textOutsideFencedCodeBlocks(text)
        guard !searchableText.isEmpty else { return nil }
        let trimmed = searchableText.trimmingCharacters(in: .whitespacesAndNewlines)

        if hasUnbalancedToken("**", in: searchableText) {
            return trimmed.hasSuffix("*") && !trimmed.hasSuffix("**") ? "*" : "**"
        }
        if hasUnbalancedToken("__", in: searchableText) {
            return trimmed.hasSuffix("_") && !trimmed.hasSuffix("__") ? "_" : "__"
        }
        if hasUnbalancedSingleDelimiter("*", in: searchableText) {
            return "*"
        }
        if hasUnbalancedSingleDelimiter("_", in: searchableText) {
            return "_"
        }
        return nil
    }

    private func textOutsideFencedCodeBlocks(_ text: String) -> String {
        var isInsideFence = false
        var trailingTextLines: [String] = []
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                isInsideFence.toggle()
                trailingTextLines.removeAll()
                continue
            }
            if !isInsideFence {
                trailingTextLines.append(line)
            }
        }
        return isInsideFence ? "" : trailingTextLines.joined(separator: "\n")
    }

    private func hasUnbalancedToken(_ token: String, in text: String) -> Bool {
        let count = text.components(separatedBy: token).count - 1
        return !count.isMultiple(of: 2)
    }

    private func hasUnbalancedSingleDelimiter(_ delimiter: Character, in text: String) -> Bool {
        let characters = Array(text)
        var count = 0
        for index in characters.indices where characters[index] == delimiter {
            let previousMatches = index > characters.startIndex && characters[characters.index(before: index)] == delimiter
            let nextIndex = characters.index(after: index)
            let nextMatches = nextIndex < characters.endIndex && characters[nextIndex] == delimiter
            if !previousMatches && !nextMatches {
                count += 1
            }
        }
        return !count.isMultiple(of: 2)
    }
}

public struct PartialTableRewriter: PartialMarkdownRewriter {
    public let name = "partial-table"

    public init() {}

    public func rewriteIfNeeded(_ text: String) -> PartialMarkdownRewrite? {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        guard let last = lines.last?.trimmingCharacters(in: .whitespaces), last.hasPrefix("|") else {
            return nil
        }

        let trailingTableLines = lines.reversed().prefix { $0.trimmingCharacters(in: .whitespaces).hasPrefix("|") }
        guard trailingTableLines.count == 1 else { return nil }

        let columns = last.split(separator: "|", omittingEmptySubsequences: false).count - 1
        let delimiter = "|" + Array(repeating: " --- |", count: max(columns, 1)).joined()
        return PartialMarkdownRewrite(text: text + "\n" + delimiter, name: name)
    }
}
