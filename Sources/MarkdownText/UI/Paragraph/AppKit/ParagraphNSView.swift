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
  static let animationDuration: CFTimeInterval = ParagraphAnimationConstants.fadeInDuration

  private(set) var paragraphContents: NSMutableAttributedString = NSMutableAttributedString()
  private(set) var lineSpacing: CGFloat?
  private var activeAnimations: [FadeAnimationData] = []
  private var fadeAnimationDisplayLink: CADisplayLink?
  private var cachedSize: CachedParagraphNSViewSize?

  var textContextMenu: TextContextMenu?
  var markdownController: MarkdownController?

  var onUrlTap: (URL) -> Void = { NSWorkspace.shared.open($0) }

  convenience init() {
    let textStorage = NSTextStorage()
    let layoutManager = NSLayoutManager()
    textStorage.addLayoutManager(layoutManager)
    let textContainer = NSTextContainer(containerSize: NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude))
    textContainer.widthTracksTextView = true
    textContainer.heightTracksTextView = false
    layoutManager.addTextContainer(textContainer)
    self.init(frame: .zero, textContainer: textContainer)
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
    activeAnimations.removeAll()
  }

  // MARK: - Appearance

  override func viewDidChangeEffectiveAppearance() {
    super.viewDidChangeEffectiveAppearance()
    AppAppearance.update(appearance: effectiveAppearance)
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

    guard let textContainer, let layoutManager = textContainer.layoutManager else {
      return .zero
    }
    textContainer.containerSize = NSSize(width: targetWidth, height: CGFloat.greatestFiniteMagnitude)
    layoutManager.ensureLayout(for: textContainer)
    let usedRect = layoutManager.usedRect(for: textContainer)
    let roundedUpSize = CGSize(width: usedRect.width.rounded(.up), height: usedRect.height.rounded(.up))
    cachedSize = CachedParagraphNSViewSize(size: roundedUpSize, targetWidth: targetWidth)
    return roundedUpSize
  }

  override func layout() {
    super.layout()
    if bounds.width != cachedSize?.targetWidth {
      invalidateCachedSize()
    }
    invalidateIntrinsicContentSize()
  }

  // MARK: - Content Update

  func setParagraphContents(_ newContents: NSMutableAttributedString, lineSpacing: CGFloat? = nil, animatedByWord: Bool) {
    AppAppearance.update(appearance: effectiveAppearance)

    guard paragraphContents != newContents || self.lineSpacing != lineSpacing else {
      return
    }
    self.paragraphContents = newContents
    self.lineSpacing = lineSpacing

    let oldLength = textStorage?.length ?? 0
    let finalString: NSMutableAttributedString
    if lineSpacing != nil {
      finalString = applyLineSpacing(to: newContents, lineSpacing: lineSpacing)
    } else {
      finalString = newContents
    }

    tearDownDisplayLink()
    invalidateCachedSize()
    textStorage?.setAttributedString(finalString)

    configureAccessibility(for: finalString)

    invalidateIntrinsicContentSize()

    let newContentLength = (textStorage?.length ?? 0) - oldLength

    if animatedByWord, newContentLength > 0 {
      let newContentRange = NSRange(location: oldLength, length: newContentLength)
      let wordRanges = finalString.splitIntoWords(withIn: newContentRange)
      let wordCount = wordRanges.count
      let delayBetweenWords: Double = ParagraphAnimationConstants.delayBetweenWordsRatio / Double(max(wordCount, 1))
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
      activeAnimations.removeAll()
    }
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

  // MARK: - Fade Animation

  @objc private func updateFadeAnimation() {
    let currentTime = CACurrentMediaTime()
    var completedAnimations: [UUID] = []

    updateTextViewWithCurrentAnimations()

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
    guard let textStorage else { return }
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
        let easedProgress = paragraphEaseOut(progress)
        animatedAlpha = easedProgress
      }

      let defaultColor = NSColor(Color.Theme.Foreground.Primary.Primary750)
      textStorage.enumerateAttribute(.foregroundColor, in: animation.range, options: []) { value, range, _ in
        let baseColor = (value as? NSColor) ?? defaultColor
        textStorage.addAttribute(.foregroundColor, value: baseColor.withAlphaComponent(animatedAlpha), range: range)
      }
    }
  }

  private func setUpDisplayLink() {
    let link = displayLink(
      target: self,
      selector: #selector(updateFadeAnimation)
    )
    link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
    link.add(to: .main, forMode: .common)
    fadeAnimationDisplayLink = link
  }

  private func tearDownDisplayLink() {
    fadeAnimationDisplayLink?.invalidate()
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

    let menu = NSMenu()

    // Add standard Copy item
    let copyItem = NSMenuItem(title: "Copy", action: #selector(copy(_:)), keyEquivalent: "c")
    menu.addItem(copyItem)
    menu.addItem(.separator())

    // Add custom groups
    for group in textContextMenu.menuGroups {
      if group.displayInline {
        for item in group.items {
          let menuItem = NSMenuItem(title: item.title, action: #selector(contextMenuItemTapped(_:)), keyEquivalent: "")
          menuItem.representedObject = ContextMenuAction(id: item.id, selectedText: selectedText)
          menuItem.target = self
          menu.addItem(menuItem)
        }
      } else {
        let submenu = NSMenu(title: group.title ?? "")
        for item in group.items {
          let menuItem = NSMenuItem(title: item.title, action: #selector(contextMenuItemTapped(_:)), keyEquivalent: "")
          menuItem.representedObject = ContextMenuAction(id: item.id, selectedText: selectedText)
          menuItem.target = self
          submenu.addItem(menuItem)
        }
        let submenuItem = NSMenuItem(title: group.title ?? "", action: nil, keyEquivalent: "")
        submenuItem.submenu = submenu
        menu.addItem(submenuItem)
      }
      menu.addItem(.separator())
    }

    // Notify controller of menu appearance
    if let markdownController {
      for group in textContextMenu.menuGroups {
        for item in group.items {
          markdownController.onContextMenuAppear(id: item.id, selectedContent: selectedText)
        }
      }
    }

    return menu
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
