import Foundation

public enum CitationMarkerPatternError: Error, Equatable {
    case invalidGroupIndex(String)
}

public struct CitationMarkerPattern: Equatable {
    public let pattern: String
    public let idGroup: Int
    public let labelPrefix: String
    public let labelGroup: Int?
    public let sourceGroup: Int?

    public init(
        pattern: String,
        idGroup: Int,
        labelPrefix: String = "",
        labelGroup: Int? = nil,
        sourceGroup: Int? = nil
    ) throws {
        guard idGroup > 0 else {
            throw CitationMarkerPatternError.invalidGroupIndex("idGroup")
        }
        if let labelGroup, labelGroup <= 0 {
            throw CitationMarkerPatternError.invalidGroupIndex("labelGroup")
        }
        if let sourceGroup, sourceGroup <= 0 {
            throw CitationMarkerPatternError.invalidGroupIndex("sourceGroup")
        }
        _ = try NSRegularExpression(pattern: pattern)
        self.pattern = pattern
        self.idGroup = idGroup
        self.labelPrefix = labelPrefix
        self.labelGroup = labelGroup
        self.sourceGroup = sourceGroup
    }

    public static let footnote = try! CitationMarkerPattern(
        pattern: #"\[\^(\w[\w.-]*)\]"#,
        idGroup: 1
    )

    fileprivate var regularExpression: NSRegularExpression {
        try! NSRegularExpression(pattern: pattern)
    }
}

public struct CitationParsingConfiguration: Equatable {
    public var markerPattern: CitationMarkerPattern?
    public var accessibilityLabelPrefix: String
    public var markerQueryItemName: String
    public var markerQueryItemValue: String
    public var citationScheme: String
    public var titleQueryItemName: String
    public var fullTitleQueryItemName: String

    public init(
        markerPattern: CitationMarkerPattern? = .footnote,
        accessibilityLabelPrefix: String = "Citation: ",
        markerQueryItemName: String = "citation",
        markerQueryItemValue: String = "true",
        citationScheme: String = "citation",
        titleQueryItemName: String = "title",
        fullTitleQueryItemName: String = "fullTitle"
    ) {
        self.markerPattern = markerPattern
        self.accessibilityLabelPrefix = accessibilityLabelPrefix
        self.markerQueryItemName = markerQueryItemName
        self.markerQueryItemValue = markerQueryItemValue
        self.citationScheme = citationScheme
        self.titleQueryItemName = titleQueryItemName
        self.fullTitleQueryItemName = fullTitleQueryItemName
    }

    public static let `default` = CitationParsingConfiguration()

    func citation(from label: String, destination: String) -> Citation? {
        guard let components = URLComponents(string: destination) else { return nil }
        let queryItems = components.queryItems ?? []
        let isSchemeCitation = components.scheme == citationScheme
        let hasMarker = queryItems.contains { $0.name == markerQueryItemName && $0.value == markerQueryItemValue }
        guard isSchemeCitation || hasMarker else { return nil }

        let title = queryItems.first(where: { $0.name == titleQueryItemName })?.value ?? label
        let fullTitle = queryItems.first(where: { $0.name == fullTitleQueryItemName })?.value
        return Citation(
            id: citationID(from: components, fallback: label),
            title: title,
            source: destination,
            url: URL(string: destination),
            fullTitle: fullTitle,
            accessibilityLabel: accessibilityLabelPrefix + (fullTitle ?? title)
        )
    }

    func markerCitation(in text: Substring, anchoredToStart: Bool) -> (citation: Citation, range: Range<Substring.Index>)? {
        guard let markerPattern else { return nil }

        let source = String(text)
        let fullRange = NSRange(source.startIndex..<source.endIndex, in: source)
        guard let match = markerPattern.regularExpression.firstMatch(in: source, range: fullRange),
              match.range.length > 0,
              !anchoredToStart || match.range.location == 0,
              let range = Range(match.range, in: source),
              let id = captureGroup(markerPattern.idGroup, in: match, source: source),
              !id.isEmpty else {
            return nil
        }

        let title = markerPattern.labelGroup.flatMap { captureGroup($0, in: match, source: source) }
            ?? markerPattern.labelPrefix + id
        let citationSource = markerPattern.sourceGroup.flatMap { captureGroup($0, in: match, source: source) }
        let lowerOffset = source.distance(from: source.startIndex, to: range.lowerBound)
        let upperOffset = source.distance(from: source.startIndex, to: range.upperBound)
        let lowerBound = text.index(text.startIndex, offsetBy: lowerOffset)
        let upperBound = text.index(text.startIndex, offsetBy: upperOffset)

        return (
            Citation(
                id: id,
                title: title,
                source: citationSource,
                url: citationSource.flatMap(URL.init(string:)),
                accessibilityLabel: accessibilityLabelPrefix + title
            ),
            lowerBound..<upperBound
        )
    }

    private func citationID(from components: URLComponents, fallback: String) -> String {
        if let host = components.host, !host.isEmpty {
            return host
        }
        let path = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return path.isEmpty ? fallback : path
    }

    private func captureGroup(_ index: Int, in match: NSTextCheckingResult, source: String) -> String? {
        guard index > 0, index < match.numberOfRanges else { return nil }
        let range = match.range(at: index)
        guard range.location != NSNotFound, let stringRange = Range(range, in: source) else {
            return nil
        }
        return String(source[stringRange])
    }
}
