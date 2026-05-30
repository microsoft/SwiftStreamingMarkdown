//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import SwiftUI
import UIKit

private final class AttachmentCitationLabel: UILabel {
  private let textInsets = InlineCitationAttachment.textInsets

  // MARK: Initialization

  init(
    title: String,
    font: UIFont,
    textColor: UIColor,
    backgroundColor: UIColor
  ) {
    super.init(frame: .zero)
    self.backgroundColor = backgroundColor
    self.layer.cornerRadius = InlineCitationAttachment.cornerRadius
    self.layer.masksToBounds = true
    self.font = font
    self.textColor = textColor
    self.textAlignment = .center
    self.numberOfLines = 1
    self.text = title

    // This prevents inline citations from being focusable in linear VoiceOver navigation
    // Citations will still be accessible via the Links rotor through the parent UITextView
    self.isAccessibilityElement = false
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Layout

  override func drawText(in rect: CGRect) {
    let insetRect = rect.inset(by: textInsets)
    super.drawText(in: insetRect)
  }

  override var intrinsicContentSize: CGSize {
    let size = super.intrinsicContentSize
    return CGSize(
      width: size.width + textInsets.left + textInsets.right,
      height: size.height + textInsets.top + textInsets.bottom
    )
  }
}

/// NSTextAttachmentViewProvider for rendering citation attachments
final class InlineCitationViewProvider: NSTextAttachmentViewProvider {
  required override init(
    textAttachment attachment: NSTextAttachment,
    parentView: UIView?,
    textLayoutManager: NSTextLayoutManager?,
    location: any NSTextLocation
  ) {
    super.init(
      textAttachment: attachment,
      parentView: parentView,
      textLayoutManager: textLayoutManager,
      location: location
    )
    tracksTextAttachmentViewBounds = true
  }

  override func loadView() {
    // Use the pre-decoded data from InlineCitationAttachment for optimal performance
    // (avoids redundant JSON parsing on every loadView call)
    guard let attachment = textAttachment as? InlineCitationAttachment,
          let data = attachment.citationData else {
      return
    }

    self.view = AttachmentCitationLabel(
      title: data.title,
      font: attachment.font,
      textColor: attachment.textColor,
      backgroundColor: attachment.backgroundColor
    )
  }
}
