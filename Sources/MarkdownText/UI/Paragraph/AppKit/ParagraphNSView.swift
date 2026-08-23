//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

#if canImport(AppKit)
import AppKit
import iosMath
import QuartzCore
import SwiftUI
import UniformTypeIdentifiers

private struct CachedParagraphNSViewSize {
  let size: CGSize
  let targetWidth: CGFloat
}

class ParagraphNSView: NSTextView {
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
  private var cachedSize: CachedParagraphNSViewSize?

  private(set) var supportsCharacterStreaming = false
  var textContextMenu: TextContextMenu?
  var markdownController: MarkdownController?

  var onUrlTap: (URL) -> Void = { NSWorkspace.shared.open($0) }

  convenience init(characterStreaming: Bool = false) {
    let textStorage = NSTextStorage()
    let layoutManager = characterStreaming
      ? CharacterStreamingLayoutManager()
      : NSLayoutManager()
    textStorage.addLayoutManager(layoutManager)
    let textContainer = NSTextContainer(containerSize: NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude))
    textContainer.widthTracksTextView = true
    textContainer.heightTracksTextView = false
    layoutManager.addTextContainer(textContainer)
    self.init(frame: .zero, textContainer: textContainer)
    supportsCharacterStreaming = characterStreaming
  }

  override init(frame frameRect: NSRect, textContainer container: NSTextContainer?) {
    super.init(frame: frameRect, textContainer: container)
    setupView()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupView()
  }

  deinit {
    tearDownDisplayLink()
    characterStreamingTimer?.invalidate()
    activeAnimation = nil
  }

  // MARK: - Appearance

  override func viewDidChangeEffectiveAppearance() {
    super.viewDidChangeEffectiveAppearance()
    AppAppearance.update(appearance: effectiveAppearance)
  }

  override func viewWillMove(toWindow newWindow: NSWindow?) {
    super.viewWillMove(toWindow: newWindow)
    if newWindow == nil, textAnimation == .characterStreaming {
      finishTextAnimation()
    }
  }

  // MARK: - Intrinsic Content Size

  override var intrinsicContentSize: NSSize {
    if let cachedSize {
      return cachedSize.size
    }
    var targetWidth = bounds.width
    if targetWidth <= 0 || targetWidth.isInfinite {
      targetWidth = NSScreen.main?.frame.width ?? 800
    }

    let measuredSize = measureSize(fittingWidth: targetWidth)
    cachedSize = CachedParagraphNSViewSize(size: measuredSize, targetWidth: targetWidth)
    return measuredSize
  }

  /// Measures the size required to lay out the current content within `width`.
  ///
  /// Uses a dedicated, throwaway layout stack instead of the view's own text container.
  /// The display container has `widthTracksTextView = true`, so its width follows the
  /// view's frame width regardless of any `containerSize` we set. When the view is
  /// measured before it has been given a frame (e.g. mid navigation transition) that
  /// tracked width is `0`, which yields a zero height and collapses the paragraph. A
  /// standalone container whose width we set directly always measures correctly.
  func measureSize(fittingWidth width: CGFloat) -> CGSize {
    guard let textStorage, textStorage.length > 0, width > 0, width.isFinite else {
      return .zero
    }
    let measuringTextStorage = NSTextStorage(attributedString: textStorage)
    let measuringLayoutManager = NSLayoutManager()
    let measuringContainer = NSTextContainer(size: NSSize(width: width, height: CGFloat.greatestFiniteMagnitude))
    measuringContainer.lineFragmentPadding = 0
    measuringContainer.maximumNumberOfLines = 0
    measuringContainer.lineBreakMode = .byWordWrapping
    measuringLayoutManager.addTextContainer(measuringContainer)
    measuringTextStorage.addLayoutManager(measuringLayoutManager)
    measuringLayoutManager.ensureLayout(for: measuringContainer)
    let usedRect = measuringLayoutManager.usedRect(for: measuringContainer)
    return CGSize(width: usedRect.width.rounded(.up), height: usedRect.height.rounded(.up))
  }

  override func layout() {
    super.layout()
    if bounds.width != cachedSize?.targetWidth {
      invalidateCachedSize()
    }
    invalidateIntrinsicContentSize()
  }

  // MARK: - Content Update

  func setParagraphContents(
    _ newContents: NSMutableAttributedString,
    lineSpacing: CGFloat? = nil,
    textAnimation: MarkdownRenderConfig.TextAnimation,
    isStreamComplete: Bool
  ) {
    AppAppearance.update(appearance: effectiveAppearance)

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
      stopCharacterStreaming()
      activeAnimation = nil
      tearDownDisplayLink()
      textStorage?.setAttributedString(finalString)
    case .fade:
      stopCharacterStreaming()
      guard contentsChanged || modeChanged else {
        invalidateIntrinsicContentSize()
        return
      }
      textStorage?.setAttributedString(finalString)
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

  // MARK: - Line Spacing

  private func applyLineSpacing(to attributedString: NSMutableAttributedString, lineSpacing: CGFloat?) -> NSMutableAttributedString {
    let result = NSMutableAttributedString(attributedString: attributedString)
    if let lineSpacing {
      let paragraphStyle = NSMutableParagraphStyle()
      paragraphStyle.lineSpacing = lineSpacing
      paragraphStyle.alignment = .left
      result.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: result.length))
    }
    return result
  }

  // MARK: - View Setup

  private func setupView() {
    if NSTextAttachment.textAttachmentViewProviderClass(forFileType: UTType.data.identifier) == nil {
      NSTextAttachment.registerViewProviderClass(LatexViewProvider.self, forFileType: UTType.data.identifier)
    }

    isEditable = false
    isSelectable = true
    drawsBackground = false
    textContainer?.lineFragmentPadding = 0
    textContainer?.widthTracksTextView = true
    textContainer?.heightTracksTextView = false
    textContainer?.maximumNumberOfLines = 0
    textContainer?.lineBreakMode = .byWordWrapping

    isVerticallyResizable = true
    isHorizontallyResizable = false

    linkTextAttributes = [:]

    setContentHuggingPriority(.defaultHigh, for: .vertical)
    setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
    setContentHuggingPriority(.defaultLow, for: .horizontal)
    setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
  }

  // MARK: - Accessibility

  private func generateAccessibilityContent(from attributedString: NSAttributedString) -> (label: String?, actions: [() -> Void])? {
    var labelComponents: [String] = []
    var hasAttachments = false
    let fullRange = NSRange(location: 0, length: attributedString.length)

    attributedString.enumerateAttributes(in: fullRange, options: []) { attrs, range, _ in
      if let attachment = attrs[.attachment] as? InlineCitationAttachment,
         let citationData = attachment.citationData {
        labelComponents.append(citationData.accessibilityLabel)
        hasAttachments = true
      } else {
        let text = attributedString.attributedSubstring(from: range).string
        if !text.isEmpty {
          labelComponents.append(text)
        }
      }
    }

    guard hasAttachments else { return nil }
    let label = labelComponents.isEmpty ? nil : labelComponents.joined()
    return (label: label, actions: [])
  }

  private func configureAccessibility(for attributedString: NSAttributedString) {
    if let content = generateAccessibilityContent(from: attributedString) {
      setAccessibilityLabel(content.label)
    } else {
      setAccessibilityLabel(attributedString.string)
    }
  }

  // MARK: - Text Animation

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
    guard let textStorage else { return }

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
    guard let textStorage else { return }
    let defaultColor = NSColor(Color.Theme.Foreground.Primary.Primary750)
    finalAttributedText.enumerateAttributes(in: range, options: []) { attributes, attributeRange, _ in
      var attributes = attributes
      let baseColor = (attributes[.foregroundColor] as? NSColor) ?? defaultColor
      attributes[.foregroundColor] = baseColor.withAlphaComponent(
        baseColor.alphaComponent * progress
      )
      textStorage.setAttributes(attributes, range: attributeRange)
    }
  }

  private func restoreFinalAttributes(in ranges: [NSRange]) {
    guard let textStorage else { return }
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
    textStorage?.setAttributedString(characterStreamingState.visibleAttributedText)
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
    characterStreamingLayoutManager?.clearAnimations()
  }

  private var characterStreamingLayoutManager: CharacterStreamingLayoutManager? {
    layoutManager as? CharacterStreamingLayoutManager
  }

  private func setUpDisplayLink() {
    guard textAnimationDisplayLink == nil else {
      return
    }
    let link = displayLink(
      target: self,
      selector: #selector(updateTextAnimation)
    )
    link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
    link.add(to: .main, forMode: .common)
    textAnimationDisplayLink = link
  }

  private func tearDownDisplayLink() {
    textAnimationDisplayLink?.invalidate()
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

  // MARK: - Link Clicks

  // swiftlint:disable:next no_any
  override func clicked(onLink link: Any, at charIndex: Int) {
    if let url = link as? URL {
      onUrlTap(url)
    } else if let string = link as? String, let url = URL.fromMixedEncodingString(string) {
      onUrlTap(url)
    }
  }

  // MARK: - Context Menu

  override func menu(for event: NSEvent) -> NSMenu? {
    guard let textContextMenu, let textStorage else {
      return super.menu(for: event)
    }

    let selectedRange = self.selectedRange()
    let clampedRange = NSIntersectionRange(selectedRange, NSRange(location: 0, length: textStorage.length))
    let selectedText = textStorage.attributedSubstring(from: clampedRange).string

    // Start from the native context menu so system items (Copy, Look Up,
    // Translate, Share, Services, …) are preserved, then inject the configured
    // groups at the top, above the system items.
    let menu = super.menu(for: event) ?? NSMenu()

    var injected: [NSMenuItem] = []
    // The built-in "Select more text" group (when enabled) is prepended by
    // `MarkdownRenderConfig.resolvedTextContextMenu`, so it renders first.
    for group in textContextMenu.menuGroups {
      if group.displayInline {
        for item in group.items {
          injected.append(makeMenuItem(for: item, selectedText: selectedText))
        }
      } else {
        let submenu = NSMenu(title: group.title ?? "")
        for item in group.items {
          submenu.addItem(makeMenuItem(for: item, selectedText: selectedText))
        }
        let submenuItem = NSMenuItem(title: group.title ?? "", action: nil, keyEquivalent: "")
        submenuItem.submenu = submenu
        injected.append(submenuItem)
      }
      injected.append(.separator())
    }

    // Insert the block in order at the top; its trailing separator divides it
    // from the native items (Copy, …) that follow.
    var insertAt = 0
    for item in injected {
      menu.insertItem(item, at: insertAt)
      insertAt += 1
    }

    // Notify controller of menu appearance (excluding the built-in item)
    if let markdownController {
      for group in textContextMenu.menuGroups {
        for item in group.items where item.id != TextSelectionConfig.selectMoreItemID {
          markdownController.onContextMenuAppear(id: item.id, selectedContent: selectedText)
        }
      }
    }

    return menu
  }

  private func makeMenuItem(for item: TextContextMenuItem, selectedText: String) -> NSMenuItem {
    if item.id == TextSelectionConfig.selectMoreItemID {
      let menuItem = NSMenuItem(title: item.title, action: #selector(selectMoreTextTapped), keyEquivalent: "")
      menuItem.target = self
      return menuItem
    }
    let menuItem = NSMenuItem(title: item.title, action: #selector(contextMenuItemTapped(_:)), keyEquivalent: "")
    menuItem.representedObject = ContextMenuAction(id: item.id, selectedText: selectedText)
    menuItem.target = self
    return menuItem
  }

  @objc private func selectMoreTextTapped() {
    markdownController?.requestTextSelection()
  }

  @objc private func contextMenuItemTapped(_ sender: NSMenuItem) {
    guard let action = sender.representedObject as? ContextMenuAction else { return }
    markdownController?.onContextMenuTap(id: action.id, selectedContent: action.selectedText)
  }
}

// MARK: - Context Menu Action Helper

private struct ContextMenuAction {
  let id: String
  let selectedText: String
}

#endif
