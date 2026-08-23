//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

#if canImport(UIKit)
import iosMath
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct AccessibilityContent {
  let label: String?
  let actions: [UIAccessibilityCustomAction]
}

private struct CachedParagraphUIViewSize {
  let size: CGSize
  let targetWidth: CGFloat
}

class ParagraphUIView: UITextView {
  private static let jsonEncoder = JSONEncoder()

  private(set) var paragraphContents: NSMutableAttributedString = NSMutableAttributedString()
  private(set) var lineSpacing: CGFloat?
  private var finalAttributedText = NSAttributedString()
  private var activeAnimation: FadeAnimationData?
  private let characterStreamingState = CharacterStreamingState()
  private var characterStreamingTimer: Timer?
  private var textAnimationDisplayLink: CADisplayLink?
  private var textAnimation: MarkdownRenderConfig.TextAnimation = .none
  private var isStreamComplete = true
  private var retainedTextStorage: NSTextStorage?
  private var cachedSize: CachedParagraphUIViewSize?

  private(set) var supportsCharacterStreaming = false
  var textContextMenu: TextContextMenu?
  var markdownController: MarkdownController?

  // To override the behaviour of this property, do so on ParagraphView's SwiftUI wrapper.
  var onUrlTap: (URL) -> Void = { UIApplication.shared.open($0) }

  override init(frame: CGRect, textContainer: NSTextContainer?) {
    super.init(frame: frame, textContainer: textContainer)
    delegate = self
    setupView()
  }

  convenience init(characterStreaming: Bool) {
    guard characterStreaming else {
      self.init(frame: .zero, textContainer: nil)
      return
    }
    let textSystem = Self.makeTextSystem()
    self.init(frame: .zero, textContainer: textSystem.container)
    retainedTextStorage = textSystem.storage
    supportsCharacterStreaming = true
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    delegate = self
    setupView()
  }

  deinit {
    tearDownDisplayLink()
    characterStreamingTimer?.invalidate()
    activeAnimation = nil
  }

  override func willMove(toWindow newWindow: UIWindow?) {
    super.willMove(toWindow: newWindow)
    // Fix for crash: "UIPreviewTarget requires that the container view is in a window". When the view is removed from the window (e.g. scrolled out in LazyVStack), we should clear the selection to prevent any pending menu or drag interactions from trying to reference the detached view.
    if newWindow == nil {
      selectedTextRange = nil
      if textAnimation == .characterStreaming {
        finishTextAnimation()
      }
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
      AppAppearance.update(style: traitCollection.userInterfaceStyle)
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

  func setParagraphContents(
    _ newContents: NSMutableAttributedString,
    lineSpacing: CGFloat? = nil,
    textAnimation: MarkdownRenderConfig.TextAnimation,
    isStreamComplete: Bool
  ) {
    // Keep the cached interface style up to date for citation preview rendering.
    // This runs on the main thread so it's safe to read traitCollection here.
    AppAppearance.update(style: traitCollection.userInterfaceStyle)

    if textAnimation == .none {
      guard paragraphContents != newContents
        || self.lineSpacing != lineSpacing
        || self.textAnimation != .none
        || self.isStreamComplete != isStreamComplete else {
        return
      }
      stopCharacterStreaming()
      activeAnimation = nil
      tearDownDisplayLink()
      self.paragraphContents = newContents
      self.lineSpacing = lineSpacing
      self.textAnimation = .none
      self.isStreamComplete = isStreamComplete
      let settledString = lineSpacing != nil
        ? applyLineSpacing(to: newContents, lineSpacing: lineSpacing)
        : newContents
      finalAttributedText = NSAttributedString(
        attributedString: settledString
      )
      invalidateCachedSize()
      attributedText = settledString
      configureAccessibility(for: settledString)
      invalidateIntrinsicContentSize()
      return
    }

    let finalString: NSMutableAttributedString
    if lineSpacing != nil {
      finalString = applyLineSpacing(to: newContents, lineSpacing: lineSpacing)
    } else {
      finalString = newContents
    }
    let previousAttributedText = finalAttributedText
    let previousText = previousAttributedText.string
    let contentsChanged = paragraphContents != newContents
      || self.lineSpacing != lineSpacing
    let modeChanged = self.textAnimation != textAnimation
    let completionChanged = self.isStreamComplete != isStreamComplete
    guard contentsChanged || modeChanged || completionChanged else {
      return
    }

    if modeChanged {
      stopCharacterStreaming()
      activeAnimation = nil
      tearDownDisplayLink()
    }
    self.paragraphContents = newContents
    self.lineSpacing = lineSpacing
    self.textAnimation = textAnimation
    self.isStreamComplete = isStreamComplete
    finalAttributedText = NSAttributedString(attributedString: finalString)
    invalidateCachedSize()
    configureAccessibility(for: finalString)

    switch textAnimation {
    case .none:
      break
    case .fade:
      stopCharacterStreaming()
      guard contentsChanged || modeChanged else {
        invalidateIntrinsicContentSize()
        return
      }
      attributedText = finalString
      let revealPlan = contentsChanged
        ? ParagraphRevealPlan.appendedText(
          previousText: previousText,
          newText: finalString.string
        )
        : nil
      guard let revealPlan else {
        activeAnimation = nil
        tearDownDisplayLink()
        invalidateIntrinsicContentSize()
        return
      }
      let currentTime = CACurrentMediaTime()
      let previousAnimation = modeChanged ? nil : activeAnimation
      activeAnimation = FadeAnimationData(
        plan: revealPlan,
        startTime: currentTime,
        previousAnimation: previousAnimation,
        contentLength: finalString.length
      )
      updateTextViewWithCurrentAnimations(at: currentTime)
      setUpDisplayLink()
    case .characterStreaming:
      activeAnimation = nil
      let currentTime = CACurrentMediaTime()
      if modeChanged {
        characterStreamingState.reset()
        if previousAttributedText.length > 0 {
          characterStreamingState.update(
            target: previousAttributedText,
            isComplete: true,
            at: currentTime
          )
          characterStreamingState.settle()
        }
      }
      characterStreamingState.update(
        target: finalString,
        isComplete: isStreamComplete,
        at: currentTime
      )
      synchronizeCharacterStreamingText()
      if characterStreamingTimer == nil {
        releaseOneCharacter(at: currentTime)
      }
    }

    invalidateIntrinsicContentSize()
  }

  func finishTextAnimation() {
    if let activeAnimation {
      restoreFinalAttributes(in: activeAnimation.segments.map(\.range))
      self.activeAnimation = nil
    }
    if textAnimation == .characterStreaming {
      characterStreamingState.settle()
      synchronizeCharacterStreamingText()
      stopCharacterStreaming()
    }
    tearDownDisplayLink()
  }

  func prepareForReuse() {
    activeAnimation = nil
    stopCharacterStreaming()
    characterStreamingState.reset()
    tearDownDisplayLink()
    paragraphContents = NSMutableAttributedString()
    lineSpacing = nil
    finalAttributedText = NSAttributedString()
    textAnimation = .none
    isStreamComplete = true
    attributedText = NSAttributedString()
    accessibilityLabel = nil
    accessibilityCustomActions = nil
    invalidateCachedSize()
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

  private static func makeTextSystem() -> (
    storage: NSTextStorage,
    container: NSTextContainer
  ) {
    let textStorage = NSTextStorage()
    let layoutManager = CharacterStreamingLayoutManager()
    let textContainer = NSTextContainer(size: .zero)
    textStorage.addLayoutManager(layoutManager)
    layoutManager.addTextContainer(textContainer)
    return (textStorage, textContainer)
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

  @objc private func updateTextAnimation() {
    let currentTime = CACurrentMediaTime()
    switch textAnimation {
    case .none:
      tearDownDisplayLink()
    case .fade:
      guard let activeAnimation else {
        tearDownDisplayLink()
        return
      }
      updateTextViewWithCurrentAnimations(at: currentTime)
      if currentTime >= activeAnimation.endTime {
        self.activeAnimation = nil
        tearDownDisplayLink()
      }
    case .characterStreaming:
      updateCharacterStreamingAnimations(at: currentTime)
      if characterStreamingState.activeAnimations.isEmpty {
        tearDownDisplayLink()
      }
    }
  }

  private func updateTextViewWithCurrentAnimations(at currentTime: CFTimeInterval = CACurrentMediaTime()) {
    guard let activeAnimation else { return }

    textStorage.beginEditing()
    defer { textStorage.endEditing() }

    for segment in activeAnimation.segments {
      guard NSMaxRange(segment.range) <= textStorage.length else {
        continue
      }
      let elapsed = currentTime - segment.startTime
      let progress = min(max(elapsed / ParagraphAnimationConstants.fadeInDuration, 0), 1)
      applyRevealProgress(paragraphEaseOut(progress), to: segment.range)
    }
  }

  private func applyRevealProgress(_ progress: CGFloat, to range: NSRange) {
    let defaultColor = UIColor(Color.Theme.Foreground.Primary.Primary750)
    finalAttributedText.enumerateAttributes(in: range, options: []) { attributes, attributeRange, _ in
      var attributes = attributes
      let baseColor = (attributes[.foregroundColor] as? UIColor) ?? defaultColor
      attributes[.foregroundColor] = baseColor.withAlphaComponent(
        baseColor.cgColor.alpha * progress
      )
      textStorage.setAttributes(attributes, range: attributeRange)
    }
  }

  private func restoreFinalAttributes(in ranges: [NSRange]) {
    textStorage.beginEditing()
    defer { textStorage.endEditing() }
    for range in ranges where NSMaxRange(range) <= finalAttributedText.length {
      finalAttributedText.enumerateAttributes(in: range, options: []) { attributes, attributeRange, _ in
        textStorage.setAttributes(attributes, range: attributeRange)
      }
    }
  }

  private func releaseOneCharacter(
    at currentTime: CFTimeInterval = CACurrentMediaTime()
  ) {
    guard textAnimation == .characterStreaming else {
      return
    }
    if characterStreamingState.releaseNext(at: currentTime) != nil {
      synchronizeCharacterStreamingText()
      updateCharacterStreamingAnimations(at: currentTime)
      setUpDisplayLink()
    }
    scheduleNextCharacterRelease()
  }

  private func synchronizeCharacterStreamingText() {
    attributedText = characterStreamingState.visibleAttributedText
    invalidateCachedSize()
    invalidateIntrinsicContentSize()
  }

  private func scheduleNextCharacterRelease() {
    guard textAnimation == .characterStreaming,
          characterStreamingState.hasPendingGrapheme,
          characterStreamingTimer == nil else {
      return
    }

    let timer = Timer(
      timeInterval: characterStreamingState.releaseDelay(
        at: CACurrentMediaTime()
      ),
      repeats: false
    ) { [weak self] _ in
      guard let self else { return }
      self.characterStreamingTimer = nil
      self.releaseOneCharacter()
    }
    RunLoop.main.add(timer, forMode: .common)
    characterStreamingTimer = timer
  }

  private func updateCharacterStreamingAnimations(at currentTime: CFTimeInterval) {
    characterStreamingState.pruneAnimations(at: currentTime)
    let animations = characterStreamingState.activeAnimations
    characterStreamingLayoutManager?.updateAnimations(
      animations,
      at: currentTime
    )
  }

  private func stopCharacterStreaming() {
    characterStreamingTimer?.invalidate()
    characterStreamingTimer = nil
    if supportsCharacterStreaming {
      characterStreamingLayoutManager?.clearAnimations()
    }
  }

  private var characterStreamingLayoutManager: CharacterStreamingLayoutManager? {
    layoutManager as? CharacterStreamingLayoutManager
  }

  private func setUpDisplayLink() {
    guard textAnimationDisplayLink == nil else {
      return
    }
    textAnimationDisplayLink = CADisplayLink(
      target: self,
      selector: #selector(updateTextAnimation)
    )
    textAnimationDisplayLink?.preferredFramesPerSecond = 60
    textAnimationDisplayLink?.add(to: .main, forMode: .common)
  }

  private func tearDownDisplayLink() {
    textAnimationDisplayLink?.remove(from: .main, forMode: .common)
    textAnimationDisplayLink = nil
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
    guard let textContextMenu else { return nil }
    return textContextMenu.buildUIMenu(
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
      for item in group.items where item.id != TextSelectionConfig.selectMoreItemID {
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
#endif
