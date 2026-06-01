//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import iosMath
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct AccessibilityContent {
  let label: String?
  let actions: [UIAccessibilityCustomAction]
}

struct FadeAnimationData {
  let id: UUID = UUID()
  let startTime: CFTimeInterval
  let duration: CFTimeInterval
  let range: NSRange
}

private struct CachedParagraphUIViewSize {
  let size: CGSize
  let targetWidth: CGFloat
}

class ParagraphUIView: UITextView {
  private static let jsonEncoder = JSONEncoder()
  static let animationDuration: CFTimeInterval = 0.5 // Animation duration for each word

  private(set) var paragraphContents: NSMutableAttributedString = NSMutableAttributedString()
  private(set) var lineSpacing: CGFloat?
  private var activeAnimations: [FadeAnimationData] = []
  private var fadeAnimationDisplayLink: CADisplayLink?
  private var cachedSize: CachedParagraphUIViewSize?

  var textContextMenu: TextContextMenu?
  var markdownController: MarkdownController?

  // To override the behaviour of this property, do so on ParagraphView's SwiftUI wrapper.
  var onUrlTap: (URL) -> Void = { UIApplication.shared.open($0) }

  override init(frame: CGRect, textContainer: NSTextContainer?) {
    super.init(frame: frame, textContainer: textContainer)
    delegate = self
    setupView()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    delegate = self
    setupView()
  }

  deinit {
    tearDownDisplayLink()
    activeAnimations.removeAll()
  }

  override func willMove(toWindow newWindow: UIWindow?) {
    super.willMove(toWindow: newWindow)
    // Fix for crash: "UIPreviewTarget requires that the container view is in a window". When the view is removed from the window (e.g. scrolled out in LazyVStack), we should clear the selection to prevent any pending menu or drag interactions from trying to reference the detached view.
    if newWindow == nil {
      selectedTextRange = nil
    }
  }

  override func resignFirstResponder() -> Bool {
    let result = super.resignFirstResponder()
    if result {
      selectedTextRange = nil
    }
    return result
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
      InlineCitationAttachment.updateInterfaceStyle(traitCollection.userInterfaceStyle)
    }
  }

  override var intrinsicContentSize: CGSize {
    if let cachedSize {
      return cachedSize.size
    }
    var targetWidth = bounds.width
    if targetWidth <= 0 || targetWidth.isInfinite {
      // When bounds.width is not valid, we have to give a best guess, otherwise Chat becomes blank in some cases sometimes. It may be related to LazyVStack.
      targetWidth = UIScreen.main.bounds.width
    }
    let targetSize = CGSize(width: targetWidth, height: .greatestFiniteMagnitude)
    let contentSize = sizeThatFits(targetSize)
    let roundedUpSize = CGSize(width: contentSize.width.rounded(.up), height: contentSize.height.rounded(.up))
    cachedSize = CachedParagraphUIViewSize(size: roundedUpSize, targetWidth: targetWidth)
    return roundedUpSize
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    if bounds.width != cachedSize?.targetWidth {
      invalidateCachedSize()
    }
    invalidateIntrinsicContentSize()
  }

  func setParagraphContents(_ newContents: NSMutableAttributedString, lineSpacing: CGFloat? = nil, animatedByWord: Bool) {
    // Keep the cached interface style up to date for citation preview rendering.
    // This runs on the main thread so it's safe to read traitCollection here.
    InlineCitationAttachment.updateInterfaceStyle(traitCollection.userInterfaceStyle)

    guard paragraphContents != newContents || self.lineSpacing != lineSpacing else {
      return
    }
    self.paragraphContents = newContents
    self.lineSpacing = lineSpacing

    let oldAttributedString: NSAttributedString = attributedText
    let finalString: NSMutableAttributedString
    if lineSpacing != nil {
      finalString = applyLineSpacing(to: newContents, lineSpacing: lineSpacing)
    } else {
      finalString = newContents
    }

    guard finalString != oldAttributedString else {
      return
    }

    // Stop display link update before updating the attributed string
    tearDownDisplayLink()
    invalidateCachedSize()
    attributedText = finalString

    configureAccessibility(for: finalString)

    invalidateIntrinsicContentSize()

    let newContentLength = attributedText.length - oldAttributedString.length

    if animatedByWord,
       newContentLength > 0 {
      // Animate word by word
      let newContentRange = NSRange(location: oldAttributedString.length, length: newContentLength)
      let wordRanges = attributedText.splitIntoWords(withIn: newContentRange)
      let wordCount = wordRanges.count
      let delayBetweenWords: Double = 0.1 / Double(wordCount)
      let baseStartTime = CACurrentMediaTime()
      for (index, wordRange) in wordRanges.enumerated() {
        let animationData = FadeAnimationData(
          startTime: baseStartTime + Double(index) * delayBetweenWords,
          duration: Self.animationDuration,
          range: wordRange
        )
        activeAnimations.append(animationData)
      }

      updateTextViewWithCurrentAnimations()

      if fadeAnimationDisplayLink == nil {
        setUpDisplayLink()
      }
    } else {
      // If no animation needed anymore, clean up all existings animations if any.
      activeAnimations.removeAll()
    }
  }

  private func applyLineSpacing(to attributedString: NSMutableAttributedString, lineSpacing: CGFloat?) -> NSMutableAttributedString {
    let result = NSMutableAttributedString(attributedString: attributedString)
    if let lineSpacing {
      result.setLineSpacing(lineSpacing)
    }
    return result
  }

  private func setupView() {
    // Only register if not already registered to prevent conflicts
    if NSTextAttachment.textAttachmentViewProviderClass(forFileType: UTType.data.identifier) == nil {
      NSTextAttachment.registerViewProviderClass(LatexViewProvider.self, forFileType: UTType.data.identifier)
    }
    if NSTextAttachment.textAttachmentViewProviderClass(forFileType: UTType.url.identifier) == nil {
      NSTextAttachment.registerViewProviderClass(InlineCitationViewProvider.self, forFileType: UTType.url.identifier)
    }

    isEditable = false
    isSelectable = true
    isScrollEnabled = false
    textAlignment = .left
    backgroundColor = .clear
    if #available(iOS 18.0, *) {
      writingToolsBehavior = .none
    }

    setContentHuggingPriority(.defaultHigh, for: .vertical)
    setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
    setContentHuggingPriority(.defaultLow, for: .horizontal)
    setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

    textContainerInset = .zero
    textContainer.lineFragmentPadding = 0
    textContainer.widthTracksTextView = true
    textContainer.heightTracksTextView = true
    textContainer.maximumNumberOfLines = 0
    textContainer.lineBreakMode = .byWordWrapping

    // When this is empty, UITextView will not override the styles set by attributes
    self.linkTextAttributes = [:]

    // Disable drag interaction to prevent crashes related to dragging from a view that might disappear
    textDragInteraction?.isEnabled = false
  }

  /// Creates a custom accessibility action that forwards activation to `onUrlTap`.
  private func makeAccessibilityAction(name: String, url: URL) -> UIAccessibilityCustomAction {
    return UIAccessibilityCustomAction(name: name) { [weak self] _ in
      guard let self else { return false }
      self.onUrlTap(url)
      return true
    }
  }

  /// Generate accessibility label and actions in a single pass (optimized)
  private func generateAccessibilityContent(from attributedString: NSAttributedString) -> AccessibilityContent? {
    var labelComponents: [String] = []
    var actions: [UIAccessibilityCustomAction] = []
    let fullRange = NSRange(location: 0, length: attributedString.length)

    attributedString.enumerateAttributes(in: fullRange, options: []) { attrs, range, _ in
      // Handle citation attachments
      if let attachment = attrs[.attachment] as? InlineCitationAttachment,
         let citationData = attachment.citationData {
        // Add to accessibility label
        labelComponents.append(citationData.accessibilityLabel)

        // Create accessibility action for citations
        let actionName = String.openCitation(citationLabel: citationData.accessibilityLabel)
        let action = makeAccessibilityAction(name: actionName, url: citationData.url)
        actions.append(action)
      } else {
        // Add the regular text for this range
        let substring = attributedString.attributedSubstring(from: range)
        let text = substring.string
        if !text.isEmpty {
          labelComponents.append(text)
        }
      }
    }

    let accessibilityLabel = labelComponents.isEmpty ? nil : labelComponents.joined()

    // Return nil if no attachments were found
    guard !actions.isEmpty else { return nil }

    return AccessibilityContent(label: accessibilityLabel, actions: actions)
  }

  /// Configure accessibility properties for the text view
  private func configureAccessibility(for attributedString: NSAttributedString) {
    // Generate the full accessibility content directly
    if let accessibilityContent = generateAccessibilityContent(from: attributedString) {
      // We have citations, use the generated content
      accessibilityLabel = accessibilityContent.label
      accessibilityCustomActions = accessibilityContent.actions
    } else {
      // No citations found, just use the plain text
      accessibilityLabel = attributedString.string
      accessibilityCustomActions = nil
    }
  }

  /// Configure visual styling for citations (separate from accessibility)
  private func configureVisualStyling(for attributedString: NSAttributedString) {
    // This method handles visual styling that should always be applied
    // regardless of accessibility configuration
    // Currently, the visual styling is handled during attachment creation
    // but this method is a placeholder for any future visual processing
  }

  // Custom easeOut curve
  private func easeOut(_ t: CGFloat) -> CGFloat {
    let c2: CGFloat = 0.1
    let c4: CGFloat = 1.0

    // Cubic Bezier evaluation
    let t2 = t * t
    let t3 = t2 * t
    let mt = 1 - t
    let mt2 = mt * mt

    return 3 * mt2 * t * c2 + 3 * mt * t2 * c4 + t3
  }

  @objc private func updateFadeAnimation() {
    let currentTime = CACurrentMediaTime()
    var completedAnimations: [UUID] = []

    updateTextViewWithCurrentAnimations()

    // Remove completed animations
    for animation in activeAnimations {
      let elapsed = currentTime - animation.startTime
      let progress = elapsed / animation.duration

      if progress >= 1.0 {
        completedAnimations.append(animation.id)
      }
    }
    activeAnimations.removeAll { completedAnimations.contains($0.id) }

    if activeAnimations.isEmpty {
      tearDownDisplayLink()
    }
  }

  private func updateTextViewWithCurrentAnimations() {
    let currentTime = CACurrentMediaTime()

    textStorage.beginEditing()
    defer { textStorage.endEditing() }

    for animation in activeAnimations {
      guard animation.range.location + animation.range.length <= textStorage.length else {
        continue
      }
      let elapsed = currentTime - animation.startTime
      let animatedAlpha: CGFloat

      if elapsed < 0 {
        animatedAlpha = 0.0
      } else {
        let progress = min(max(elapsed / animation.duration, 0.0), 1.0)
        let easedProgress = easeOut(progress) // Apply ease-out curve
        animatedAlpha = easedProgress
      }

      // Apply alpha to this animation's range, preserving each span's
      // existing foreground color. Spans with no foreground color get a
      // sensible default so they still fade in instead of disappearing.
      let defaultColor = UIColor(Color.Theme.Foreground.Primary.Primary750)
      textStorage.enumerateAttribute(.foregroundColor, in: animation.range, options: []) { value, range, _ in
        let baseColor = (value as? UIColor) ?? defaultColor
        textStorage.addAttribute(.foregroundColor, value: baseColor.withAlphaComponent(animatedAlpha), range: range)
      }
    }
  }

  private func setUpDisplayLink() {
    fadeAnimationDisplayLink = CADisplayLink(target: self, selector: #selector(updateFadeAnimation))
    fadeAnimationDisplayLink?.preferredFramesPerSecond = 60
    fadeAnimationDisplayLink?.add(to: .main, forMode: .common)
  }

  private func tearDownDisplayLink() {
    fadeAnimationDisplayLink?.remove(from: .main, forMode: .common)
    fadeAnimationDisplayLink = nil
  }

  private func invalidateCachedSize() {
    cachedSize = nil
  }

  func setTextContextMenu(_ menu: TextContextMenu?) {
    textContextMenu = menu
  }

  func setMarkdownController(_ controller: MarkdownController?) {
    markdownController = controller
  }
}

// MARK: - UITextViewDelegate
extension ParagraphUIView: UITextViewDelegate {
  func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
    self.onUrlTap(URL)
    return false
  }

  func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange) -> Bool {
    // Check if this is our custom citation attachment with pre-decoded data
    if let citationAttachment = textAttachment as? InlineCitationAttachment,
       let citationData = citationAttachment.citationData {
      self.onUrlTap(citationData.url)
      return false
    }

    return false
  }

  func textView(_ textView: UITextView, editMenuForTextIn range: NSRange, suggestedActions: [UIMenuElement]) -> UIMenu? {
    return textContextMenu?.buildUIMenu(
      textView: textView,
      selectedRange: range,
      suggestedActions: suggestedActions,
      markdownController: markdownController
    )
  }

  func textView(_ textView: UITextView, willPresentEditMenuWith animator: any UIEditMenuInteractionAnimating) {
    guard let textContextMenu, let markdownController else { return }
    let clampedRange = NSIntersectionRange(textView.selectedRange, NSRange(location: 0, length: textView.attributedText.length))
    let selectedText = textView.attributedText.attributedSubstring(from: clampedRange).string
    for group in textContextMenu.menuGroups {
      for item in group.items {
        markdownController.onContextMenuAppear(id: item.id, selectedContent: selectedText)
      }
    }
  }
}

fileprivate extension NSMutableAttributedString {
  func setLineSpacing(_ lineSpacing: CGFloat) {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineSpacing = lineSpacing
    paragraphStyle.alignment = .left
    addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: length))
  }
}

struct LatexAttachmentData: Codable {
  let latex: String
  let fontSize: CGFloat
  let lightTextColor: String
  let darkTextColor: String
}

extension LatexAttachmentData {
  var resolvedTextColor: UIColor {
    let fallback = UIColor(Color.Theme.Foreground.Primary.Primary750)
    guard let lightColor = UIColor(hex: lightTextColor),
          let darkColor = UIColor(hex: darkTextColor) else {
      return fallback
    }
    return UIColor { trait in
      trait.userInterfaceStyle == .dark ? darkColor : lightColor
    }
  }
}

final class LatexViewProvider: NSTextAttachmentViewProvider {
  private let latex: String
  private let fontSize: CGFloat
  private let textColor: UIColor
  private static let jsonDecoder = JSONDecoder()

  required override init(textAttachment attachment: NSTextAttachment,
                         parentView: UIView?,
                         textLayoutManager: NSTextLayoutManager?,
                         location: any NSTextLocation) {

    var tempLatex = ""
    var tempFontSize = Typography.base.uiFont.pointSize
    var tempTextColor: UIColor = UIColor(Color.Theme.Foreground.Primary.Primary750)
    if let data = attachment.contents {
      if let attachmentData = try? Self.jsonDecoder.decode(LatexAttachmentData.self, from: data) {
        tempLatex = attachmentData.latex
        tempFontSize = attachmentData.fontSize
        tempTextColor = attachmentData.resolvedTextColor
      }
    }
    latex = tempLatex
    fontSize = tempFontSize
    textColor = tempTextColor

    super.init(textAttachment: attachment,
               parentView: parentView,
               textLayoutManager: textLayoutManager,
               location: location)

    tracksTextAttachmentViewBounds = true
  }

  override func loadView() {
    let label = MTMathUILabel()
    label.latex = latex
    label.textColor = textColor
    label.displayErrorInline = false
    label.fontSize = fontSize
    label.setContentHuggingPriority(.defaultHigh, for: .vertical)
    self.view = label
  }

  override func attachmentBounds(for attributes: [NSAttributedString.Key: Any],
                                 location: any NSTextLocation,
                                 textContainer: NSTextContainer?,
                                 proposedLineFragment: CGRect,
                                 position: CGPoint) -> CGRect {
    guard let mathLabel = view as? MTMathUILabel else {
      return .zero
    }
    mathLabel.sizeToFit()
    // It's a known issue that MTMathUILabel may be cut off for some short statement. Manually add 1 to the height fix it.
    let height = mathLabel.bounds.height.rounded(.up) + 1.0
    let font = attributes[.font] as? UIFont ?? UIFont.systemFont(ofSize: fontSize)
    let yOffset = (font.xHeight - height) / 2.0
    return CGRect(x: 0, y: yOffset, width: mathLabel.bounds.width.rounded(.up), height: height)
  }
}
