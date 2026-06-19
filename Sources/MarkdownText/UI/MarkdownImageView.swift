//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import SwiftUI
import UIKit

struct MarkdownImageView: View {
  @Environment(\.markdownConfig) private var config: MarkdownRenderConfig

  let image: MarkdownImage

  var body: some View {
    if let customView = config.customViewBuilder?.view(for: .image(image)) {
      customView
    } else {
      defaultImageView
    }
  }

  @ViewBuilder
  private var defaultImageView: some View {
    if let uiImage {
      renderedImage(Image(uiImage: uiImage))
    } else if let remoteURL {
      AsyncImage(url: remoteURL) { phase in
        switch phase {
        case .empty:
          placeholder(systemImage: "photo", text: image.alternativeText)
        case .success(let loadedImage):
          renderedImage(loadedImage)
        case .failure:
          placeholder(systemImage: "exclamationmark.triangle", text: fallbackText)
        @unknown default:
          placeholder(systemImage: "photo", text: fallbackText)
        }
      }
    } else {
      placeholder(systemImage: "photo", text: fallbackText)
    }
  }

  private func renderedImage(_ image: Image) -> some View {
    image
      .resizable()
      .scaledToFit()
      .frame(maxWidth: .infinity, alignment: .leading)
      .accessibilityLabel(accessibilityLabel)
  }

  private func placeholder(systemImage: String, text: String) -> some View {
    HStack(spacing: 10) {
      Image(systemName: systemImage)
        .font(.system(size: 18, weight: .semibold))
      Text(text.isEmpty ? "Image" : text)
        .font(.caption)
        .lineLimit(2)
        .multilineTextAlignment(.leading)
      Spacer(minLength: 0)
    }
    .foregroundStyle(Color(config.paragraphStyle.textColor).opacity(0.72))
    .padding(12)
    .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
    .background(Color(config.paragraphStyle.textColor).opacity(0.08))
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .accessibilityLabel(accessibilityLabel)
  }

  private var uiImage: UIImage? {
    if let image = UIImage(named: image.source) {
      return image
    }

    if let fileURL, let image = UIImage(contentsOfFile: fileURL.path) {
      return image
    }

    return nil
  }

  private var remoteURL: URL? {
    guard let url = URL.fromMixedEncodingString(image.source),
          let scheme = url.scheme?.lowercased(),
          scheme == "http" || scheme == "https"
    else {
      return nil
    }

    return url
  }

  private var fileURL: URL? {
    guard let url = URL.fromMixedEncodingString(image.source),
          url.isFileURL
    else {
      return nil
    }

    return url
  }

  private var fallbackText: String {
    if !image.alternativeText.isEmpty {
      return image.alternativeText
    }

    return image.source
  }

  private var accessibilityLabel: String {
    if !image.alternativeText.isEmpty {
      return image.alternativeText
    }

    return image.title ?? image.source
  }
}
