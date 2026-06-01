//
//  Copyright © 2025 Microsoft. All rights reserved.
//


import Foundation

/// Encapsulates how inline citations are encoded into and decoded from
/// markdown link URLs. Hosts the literal marker string used as the link
/// text together with the query-parameter names that carry the citation's
/// display title and accessibility label, so downstream apps can change
/// the on-the-wire format without touching the rendering pipeline.
public struct CitationCoder: Hashable, Sendable {

  /// Literal string that appears as the link text of a citation
  /// (`[<citationMarker>](<url>)`) and as the value of the
  /// `citationMarkerQueryParam` query item on the URL.
  public let citationMarker: String
  /// Name of the query param whose value must equal `citationMarker` for the
  /// URL to be recognized as a citation.
  public let citationMarkerQueryParam: String
  /// Name of the query param that carries the citation's user-visible title.
  public let citationTextQueryParam: String
  /// Name of the query param that carries the citation's accessibility label
  /// (typically a longer, more descriptive form of the title).
  public let citationA11yTextQueryParam: String

  public init(
    citationMarker: String,
    citationMarkerQueryParam: String,
    citationTextQueryParam: String,
    citationA11yTextQueryParam: String
  ) {
    self.citationMarker = citationMarker
    self.citationMarkerQueryParam = citationMarkerQueryParam
    self.citationTextQueryParam = citationTextQueryParam
    self.citationA11yTextQueryParam = citationA11yTextQueryParam
  }

  // MARK: - Detection

  /// Whether the given markdown link text matches the configured marker.
  private func isCitationMarker(linkText: String) -> Bool {
    linkText == citationMarker
  }

  /// Whether the given URL carries the configured marker query param/value.
  private func isCitationURL(_ url: URL) -> Bool {
    URLComponents(url: url, resolvingAgainstBaseURL: true)?
      .queryItems?
      .contains(where: { $0.name == citationMarkerQueryParam && $0.value == citationMarker })
      ?? false
  }

  /// Convenience for the combined check used by the markdown converter: both
  /// the link text and the URL must identify the link as a citation.
  func isCitation(linkText: String, url: URL) -> Bool {
    isCitationMarker(linkText: linkText) && isCitationURL(url)
  }

  // MARK: - Decoding

  /// Decode a markdown link destination into citation payload data, or return
  /// nil if the URL is malformed or missing required query params.
  func decode(linkDestination: String) -> InlineAttachmentData? {
    guard let url = URL.fromMixedEncodingString(linkDestination),
          let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
          let queryItems = components.queryItems,
          let title = queryItems.first(where: { $0.name == citationTextQueryParam })?.value,
          let a11yLabel = queryItems.first(where: { $0.name == citationA11yTextQueryParam })?.value
    else {
      return nil
    }
    return InlineAttachmentData(
      type: .citation,
      title: title,
      accessibilityLabel: a11yLabel,
      url: url
    )
  }
}

extension CitationCoder {
  /// Default coder using the historical query-param names and marker UUID.
  public static let `default` = CitationCoder(
    citationMarker: "9F742443",
    citationMarkerQueryParam: "citationMarker",
    citationTextQueryParam: "citationTitle",
    citationA11yTextQueryParam: "citationA11yValue"
  )
}
