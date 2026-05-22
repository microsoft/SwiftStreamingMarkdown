import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public struct StreamingMarkdownConfiguration {
    public var parseOptions: StreamingMarkdownParseOptions
    public var designSystem: StreamingMarkdownDesignSystem
    public var citationConfiguration: CitationParsingConfiguration
    public var citationPresentation: CitationPresentationStyle
    public var animationPolicy: StreamingMarkdownAnimationPolicy
    public var syntaxHighlighter: (@Sendable (_ code: String, _ language: String?) -> AttributedString?)?

    public var theme: StreamingMarkdownTheme {
        get { designSystem.theme }
        set { designSystem.theme = newValue }
    }

    public init(
        parseOptions: StreamingMarkdownParseOptions = .init(),
        designSystem: StreamingMarkdownDesignSystem = .default,
        citationConfiguration: CitationParsingConfiguration = .default,
        citationPresentation: CitationPresentationStyle = .inlinePills,
        animationPolicy: StreamingMarkdownAnimationPolicy = .automatic,
        syntaxHighlighter: (@Sendable (_ code: String, _ language: String?) -> AttributedString?)? = nil
    ) {
        self.parseOptions = parseOptions
        self.designSystem = designSystem
        self.citationConfiguration = citationConfiguration
        self.citationPresentation = citationPresentation
        self.animationPolicy = animationPolicy
        self.syntaxHighlighter = syntaxHighlighter
    }

    public init(
        parseOptions: StreamingMarkdownParseOptions = .init(),
        theme: StreamingMarkdownTheme,
        citationConfiguration: CitationParsingConfiguration = .default,
        citationPresentation: CitationPresentationStyle = .inlinePills,
        animationPolicy: StreamingMarkdownAnimationPolicy = .automatic,
        syntaxHighlighter: (@Sendable (_ code: String, _ language: String?) -> AttributedString?)? = nil
    ) {
        self.parseOptions = parseOptions
        self.designSystem = StreamingMarkdownDesignSystem(name: "Custom", theme: theme)
        self.citationConfiguration = citationConfiguration
        self.citationPresentation = citationPresentation
        self.animationPolicy = animationPolicy
        self.syntaxHighlighter = syntaxHighlighter
    }

    public static let `default` = StreamingMarkdownConfiguration()
}

public enum StreamingMarkdownAnimationPolicy: Equatable, Sendable {
    case automatic
    case enabled
    case disabled

    public func shouldAnimate(accessibilityReduceMotion: Bool) -> Bool {
        switch self {
        case .automatic:
            !accessibilityReduceMotion
        case .enabled:
            true
        case .disabled:
            false
        }
    }
}

public struct StreamingMarkdownDesignSystem {
    public var name: String
    public var theme: StreamingMarkdownTheme
    public var layout: StreamingMarkdownLayout

    public init(
        name: String,
        theme: StreamingMarkdownTheme = .default,
        layout: StreamingMarkdownLayout = .default
    ) {
        self.name = name
        self.theme = theme
        self.layout = layout
    }

    public static let `default` = StreamingMarkdownDesignSystem(name: "SF Pro")
    public static let systemDefault = StreamingMarkdownDesignSystem(
        name: "System Default",
        theme: .systemDefault,
        layout: .default
    )
    public static let humanist = StreamingMarkdownDesignSystem(
        name: "Humanist",
        theme: .humanist,
        layout: .humanist
    )
    public static let seriousBusiness = StreamingMarkdownDesignSystem(
        name: "Serious Business",
        theme: .seriousBusiness,
        layout: .seriousBusiness
    )
    public static let paperwork = StreamingMarkdownDesignSystem(
        name: "Paperwork",
        theme: .paperwork,
        layout: .paperwork
    )
    public static let tailoredSuit = StreamingMarkdownDesignSystem(
        name: "Tailored Suit",
        theme: .tailoredSuit,
        layout: .tailoredSuit
    )
    public static let jazzHands = StreamingMarkdownDesignSystem(
        name: "Jazz Hands",
        theme: .jazzHands,
        layout: .jazzHands
    )
    public static let alternativeMan = StreamingMarkdownDesignSystem(
        name: "Alternative Man",
        theme: .alternativeMan,
        layout: .alternativeMan
    )
    public static let rationalist = StreamingMarkdownDesignSystem(
        name: "Rationalist",
        theme: .rationalist,
        layout: .rationalist
    )
}

public struct StreamingMarkdownParseOptions: Equatable {
    public var enablesSpeculativeRewrites: Bool
    public var customRewriters: [any PartialMarkdownRewriter]

    public init(
        enablesSpeculativeRewrites: Bool = true,
        customRewriters: [any PartialMarkdownRewriter] = []
    ) {
        self.enablesSpeculativeRewrites = enablesSpeculativeRewrites
        self.customRewriters = customRewriters
    }

    public static func == (lhs: StreamingMarkdownParseOptions, rhs: StreamingMarkdownParseOptions) -> Bool {
        lhs.enablesSpeculativeRewrites == rhs.enablesSpeculativeRewrites
    }
}

public struct StreamingMarkdownLayout {
    public var blockSpacing: CGFloat
    public var inlineSpacing: CGFloat
    public var inlineLineSpacing: CGFloat
    public var headingTopPadding: CGFloat
    public var listItemSpacing: CGFloat
    public var listMarkerSpacing: CGFloat
    public var quoteBarWidth: CGFloat
    public var quoteContentSpacing: CGFloat
    public var codeOuterPadding: CGFloat
    public var codeInnerPadding: CGFloat
    public var codeCornerRadius: CGFloat
    public var inlineCodeHorizontalPadding: CGFloat
    public var inlineCodeVerticalPadding: CGFloat
    public var inlineCodeCornerRadius: CGFloat
    public var citationHorizontalPadding: CGFloat
    public var citationVerticalPadding: CGFloat
    public var tableCornerRadius: CGFloat
    public var tableCellPadding: CGFloat
    public var tableMinColumnWidth: CGFloat
    public var tableMaxColumnWidth: CGFloat

    public init(
        blockSpacing: CGFloat = 12,
        inlineSpacing: CGFloat = 2,
        inlineLineSpacing: CGFloat = 4,
        headingTopPadding: CGFloat = 8,
        listItemSpacing: CGFloat = 6,
        listMarkerSpacing: CGFloat = 8,
        quoteBarWidth: CGFloat = 3,
        quoteContentSpacing: CGFloat = 10,
        codeOuterPadding: CGFloat = 10,
        codeInnerPadding: CGFloat = 12,
        codeCornerRadius: CGFloat = 10,
        inlineCodeHorizontalPadding: CGFloat = 4,
        inlineCodeVerticalPadding: CGFloat = 2,
        inlineCodeCornerRadius: CGFloat = 4,
        citationHorizontalPadding: CGFloat = 6,
        citationVerticalPadding: CGFloat = 2,
        tableCornerRadius: CGFloat = 8,
        tableCellPadding: CGFloat = 8,
        tableMinColumnWidth: CGFloat = 96,
        tableMaxColumnWidth: CGFloat = 180
    ) {
        self.blockSpacing = blockSpacing
        self.inlineSpacing = inlineSpacing
        self.inlineLineSpacing = inlineLineSpacing
        self.headingTopPadding = headingTopPadding
        self.listItemSpacing = listItemSpacing
        self.listMarkerSpacing = listMarkerSpacing
        self.quoteBarWidth = quoteBarWidth
        self.quoteContentSpacing = quoteContentSpacing
        self.codeOuterPadding = codeOuterPadding
        self.codeInnerPadding = codeInnerPadding
        self.codeCornerRadius = codeCornerRadius
        self.inlineCodeHorizontalPadding = inlineCodeHorizontalPadding
        self.inlineCodeVerticalPadding = inlineCodeVerticalPadding
        self.inlineCodeCornerRadius = inlineCodeCornerRadius
        self.citationHorizontalPadding = citationHorizontalPadding
        self.citationVerticalPadding = citationVerticalPadding
        self.tableCornerRadius = tableCornerRadius
        self.tableCellPadding = tableCellPadding
        self.tableMinColumnWidth = tableMinColumnWidth
        self.tableMaxColumnWidth = tableMaxColumnWidth
    }

    public static let `default` = StreamingMarkdownLayout()
    public static let humanist = StreamingMarkdownLayout(
        blockSpacing: 12,
        inlineSpacing: 3,
        inlineLineSpacing: 4,
        headingTopPadding: 8,
        listItemSpacing: 6,
        listMarkerSpacing: 8,
        quoteBarWidth: 3,
        quoteContentSpacing: 10,
        codeOuterPadding: 10,
        codeInnerPadding: 12,
        codeCornerRadius: 12,
        inlineCodeHorizontalPadding: 4,
        inlineCodeVerticalPadding: 2,
        inlineCodeCornerRadius: 4,
        citationHorizontalPadding: 6,
        citationVerticalPadding: 2,
        tableCornerRadius: 12,
        tableCellPadding: 8,
        tableMinColumnWidth: 120,
        tableMaxColumnWidth: 180
    )
    public static let seriousBusiness = StreamingMarkdownLayout(
        blockSpacing: 12,
        inlineSpacing: 3,
        inlineLineSpacing: 4,
        headingTopPadding: 12,
        listItemSpacing: 6,
        listMarkerSpacing: 4,
        quoteBarWidth: 2,
        quoteContentSpacing: 10,
        codeOuterPadding: 0,
        codeInnerPadding: 12,
        codeCornerRadius: 12,
        inlineCodeHorizontalPadding: 4,
        inlineCodeVerticalPadding: 2,
        inlineCodeCornerRadius: 4,
        citationHorizontalPadding: 4,
        citationVerticalPadding: 2,
        tableCornerRadius: 8,
        tableCellPadding: 8,
        tableMinColumnWidth: 96,
        tableMaxColumnWidth: 164
    )
    public static let paperwork = StreamingMarkdownLayout(
        blockSpacing: 12,
        inlineSpacing: 3,
        inlineLineSpacing: 4,
        headingTopPadding: 12,
        listItemSpacing: 6,
        listMarkerSpacing: 4,
        quoteBarWidth: 2,
        quoteContentSpacing: 10,
        codeOuterPadding: 0,
        codeInnerPadding: 12,
        codeCornerRadius: 8,
        inlineCodeHorizontalPadding: 4,
        inlineCodeVerticalPadding: 2,
        inlineCodeCornerRadius: 4,
        citationHorizontalPadding: 4,
        citationVerticalPadding: 2,
        tableCornerRadius: 8,
        tableCellPadding: 8,
        tableMinColumnWidth: 96,
        tableMaxColumnWidth: 164
    )
    public static let tailoredSuit = StreamingMarkdownLayout(
        blockSpacing: 12,
        inlineSpacing: 3,
        inlineLineSpacing: 4,
        headingTopPadding: 12,
        listItemSpacing: 6,
        listMarkerSpacing: 4,
        quoteBarWidth: 2,
        quoteContentSpacing: 10,
        codeOuterPadding: 0,
        codeInnerPadding: 12,
        codeCornerRadius: 12,
        inlineCodeHorizontalPadding: 4,
        inlineCodeVerticalPadding: 2,
        inlineCodeCornerRadius: 4,
        citationHorizontalPadding: 6,
        citationVerticalPadding: 2,
        tableCornerRadius: 10,
        tableCellPadding: 12,
        tableMinColumnWidth: 120,
        tableMaxColumnWidth: 200
    )
    public static let jazzHands = StreamingMarkdownLayout(
        blockSpacing: 12,
        inlineSpacing: 3,
        inlineLineSpacing: 4,
        headingTopPadding: 12,
        listItemSpacing: 6,
        listMarkerSpacing: 4,
        quoteBarWidth: 2,
        quoteContentSpacing: 10,
        codeOuterPadding: 0,
        codeInnerPadding: 12,
        codeCornerRadius: 0,
        inlineCodeHorizontalPadding: 4,
        inlineCodeVerticalPadding: 2,
        inlineCodeCornerRadius: 4,
        citationHorizontalPadding: 4,
        citationVerticalPadding: 2,
        tableCornerRadius: 0,
        tableCellPadding: 8,
        tableMinColumnWidth: 120,
        tableMaxColumnWidth: 200
    )
    public static let alternativeMan = StreamingMarkdownLayout(
        blockSpacing: 14,
        inlineSpacing: 3,
        inlineLineSpacing: 4,
        headingTopPadding: 10,
        listItemSpacing: 7,
        listMarkerSpacing: 8,
        quoteBarWidth: 3,
        quoteContentSpacing: 12,
        codeOuterPadding: 10,
        codeInnerPadding: 12,
        codeCornerRadius: 14,
        inlineCodeHorizontalPadding: 5,
        inlineCodeVerticalPadding: 2,
        inlineCodeCornerRadius: 6,
        citationHorizontalPadding: 7,
        citationVerticalPadding: 3,
        tableCornerRadius: 14,
        tableCellPadding: 10,
        tableMinColumnWidth: 116,
        tableMaxColumnWidth: 184
    )
    public static let rationalist = StreamingMarkdownLayout(
        blockSpacing: 15,
        inlineSpacing: 3,
        inlineLineSpacing: 5,
        headingTopPadding: 10,
        listItemSpacing: 7,
        listMarkerSpacing: 8,
        quoteBarWidth: 3,
        quoteContentSpacing: 12,
        codeOuterPadding: 10,
        codeInnerPadding: 12,
        codeCornerRadius: 10,
        inlineCodeHorizontalPadding: 5,
        inlineCodeVerticalPadding: 2,
        inlineCodeCornerRadius: 5,
        citationHorizontalPadding: 7,
        citationVerticalPadding: 3,
        tableCornerRadius: 10,
        tableCellPadding: 10,
        tableMinColumnWidth: 116,
        tableMaxColumnWidth: 184
    )
}

public struct StreamingMarkdownTheme {
    public var textFont: Font
    public var strongTextFont: Font
    public var emphasisTextFont: Font
    public var headingFont: Font
    public var heading1Font: Font
    public var heading2Font: Font
    public var heading3Font: Font
    public var heading4Font: Font
    public var heading5Font: Font
    public var heading6Font: Font
    public var captionFont: Font
    public var citationFont: Font
    public var tableTextFont: Font
    public var tableHeaderFont: Font
    public var codeFont: Font
    public var pageBackground: Color
    public var surfaceBackground: Color
    public var controlBackground: Color
    public var textColor: Color
    public var secondaryTextColor: Color
    public var linkColor: Color
    public var codeForeground: Color
    public var codeBackground: Color
    public var codeBlockBackground: Color
    public var codeActionForeground: Color
    public var tableBorderColor: Color
    public var tableHeaderBackground: Color
    public var tableCellBackground: Color
    public var tableActionForeground: Color
    public var citationForeground: Color
    public var citationBackground: Color
    public var quoteBarColor: Color
    public var quoteBackground: Color
    public var mathColor: Color

    public init(
        textFont: Font = .body,
        strongTextFont: Font? = nil,
        emphasisTextFont: Font? = nil,
        headingFont: Font = .headline,
        heading1Font: Font? = nil,
        heading2Font: Font? = nil,
        heading3Font: Font? = nil,
        heading4Font: Font? = nil,
        heading5Font: Font? = nil,
        heading6Font: Font? = nil,
        captionFont: Font = .caption,
        citationFont: Font = .caption2.bold(),
        tableTextFont: Font? = nil,
        tableHeaderFont: Font? = nil,
        codeFont: Font = .system(.body, design: .monospaced),
        pageBackground: Color = Color.clear,
        surfaceBackground: Color = Color.clear,
        controlBackground: Color = Color.clear,
        textColor: Color = .primary,
        secondaryTextColor: Color = .secondary,
        linkColor: Color = .blue,
        codeForeground: Color = .primary,
        codeBackground: Color = Color.gray.opacity(0.12),
        codeBlockBackground: Color? = nil,
        codeActionForeground: Color? = nil,
        tableBorderColor: Color = Color.gray.opacity(0.35),
        tableHeaderBackground: Color = Color.gray.opacity(0.12),
        tableCellBackground: Color = .clear,
        tableActionForeground: Color? = nil,
        citationForeground: Color = .blue,
        citationBackground: Color = Color.blue.opacity(0.12),
        quoteBarColor: Color = .secondary,
        quoteBackground: Color = .clear,
        mathColor: Color = .primary
    ) {
        self.textFont = textFont
        self.strongTextFont = strongTextFont ?? textFont.bold()
        self.emphasisTextFont = emphasisTextFont ?? textFont.italic()
        self.headingFont = headingFont
        self.heading1Font = heading1Font ?? headingFont
        self.heading2Font = heading2Font ?? headingFont
        self.heading3Font = heading3Font ?? headingFont
        self.heading4Font = heading4Font ?? headingFont
        self.heading5Font = heading5Font ?? headingFont
        self.heading6Font = heading6Font ?? headingFont
        self.captionFont = captionFont
        self.citationFont = citationFont
        self.tableTextFont = tableTextFont ?? textFont
        self.tableHeaderFont = tableHeaderFont ?? textFont.bold()
        self.codeFont = codeFont
        self.pageBackground = pageBackground
        self.surfaceBackground = surfaceBackground
        self.controlBackground = controlBackground
        self.textColor = textColor
        self.secondaryTextColor = secondaryTextColor
        self.linkColor = linkColor
        self.codeForeground = codeForeground
        self.codeBackground = codeBackground
        self.codeBlockBackground = codeBlockBackground ?? codeBackground
        self.codeActionForeground = codeActionForeground ?? secondaryTextColor
        self.tableBorderColor = tableBorderColor
        self.tableHeaderBackground = tableHeaderBackground
        self.tableCellBackground = tableCellBackground
        self.tableActionForeground = tableActionForeground ?? secondaryTextColor
        self.citationForeground = citationForeground
        self.citationBackground = citationBackground
        self.quoteBarColor = quoteBarColor
        self.quoteBackground = quoteBackground
        self.mathColor = mathColor
    }

    public func headingFont(level: Int) -> Font {
        switch level {
        case 1: heading1Font
        case 2: heading2Font
        case 3: heading3Font
        case 4: heading4Font
        case 5: heading5Font
        default: heading6Font
        }
    }

    public static let `default` = StreamingMarkdownTheme(
        textFont: .body,
        strongTextFont: .headline,
        emphasisTextFont: .body.italic(),
        headingFont: .title3.bold(),
        heading1Font: .largeTitle.bold(),
        heading2Font: .title.bold(),
        heading3Font: .title2.bold(),
        heading4Font: .title3.bold(),
        heading5Font: .headline,
        heading6Font: .subheadline.bold(),
        captionFont: .caption,
        citationFont: .caption2.bold(),
        tableTextFont: .body,
        tableHeaderFont: .headline,
        codeFont: .system(.body, design: .monospaced),
        pageBackground: .humanist(light: 0xFFFFFF, dark: 0x000000),
        surfaceBackground: .humanist(light: 0xFFFFFF, dark: 0x1C1C1E),
        controlBackground: .humanist(light: 0xF2F2F7, dark: 0x2C2C2E),
        textColor: .humanist(light: 0x000000, dark: 0xFFFFFF),
        secondaryTextColor: .humanist(light: 0x6C6C70, dark: 0xAEAEB2),
        linkColor: .humanist(light: 0x007AFF, dark: 0x0A84FF),
        codeForeground: .humanist(light: 0x000000, dark: 0xFFFFFF),
        codeBackground: .humanist(light: 0xF2F2F7, dark: 0x2C2C2E),
        codeBlockBackground: .humanist(light: 0xF2F2F7, dark: 0x1C1C1E),
        tableBorderColor: .humanist(light: 0xC6C6C8, dark: 0x38383A),
        tableHeaderBackground: .humanist(light: 0xF2F2F7, dark: 0x2C2C2E),
        tableCellBackground: .clear,
        citationForeground: .humanist(light: 0x007AFF, dark: 0x0A84FF),
        citationBackground: .humanist(light: 0xE5F0FF, dark: 0x102A43),
        quoteBarColor: .humanist(light: 0xC6C6C8, dark: 0x48484A),
        quoteBackground: .clear,
        mathColor: .humanist(light: 0x000000, dark: 0xFFFFFF)
    )
    public static let systemDefault = StreamingMarkdownTheme(
        headingFont: .title3.bold(),
        heading1Font: .largeTitle.bold(),
        heading2Font: .title.bold(),
        heading3Font: .title2.bold(),
        heading4Font: .title3.bold(),
        heading5Font: .headline,
        heading6Font: .subheadline.bold(),
        pageBackground: .humanist(light: 0xFFFFFF, dark: 0x0F1119),
        surfaceBackground: .humanist(light: 0xFFFFFF, dark: 0x171A25),
        controlBackground: .humanist(light: 0xF5F5F5, dark: 0x1F2431)
    )
    public static let humanist = StreamingMarkdownTheme(
        textFont: .system(size: 17, weight: .regular),
        strongTextFont: .system(size: 17, weight: .semibold),
        emphasisTextFont: .system(size: 17, weight: .regular).italic(),
        headingFont: .system(size: 20, weight: .semibold),
        heading1Font: .system(size: 28, weight: .medium),
        heading2Font: .system(size: 24, weight: .semibold),
        heading3Font: .system(size: 20, weight: .semibold),
        heading4Font: .system(size: 17, weight: .semibold),
        heading5Font: .system(size: 17, weight: .semibold),
        heading6Font: .system(size: 17, weight: .semibold),
        captionFont: .system(size: 15, weight: .medium),
        citationFont: .system(size: 12, weight: .medium),
        tableTextFont: .system(size: 15, weight: .regular),
        tableHeaderFont: .system(size: 15, weight: .semibold),
        codeFont: .system(size: 16, design: .monospaced),
        pageBackground: .humanist(light: 0xF8F4F1, dark: 0x0F1119),
        surfaceBackground: .humanist(light: 0xFFFFFF, dark: 0x1C2338, lightAlpha: 0.72),
        controlBackground: .humanist(light: 0xFFFFFF, dark: 0x1F2431, lightAlpha: 0.70),
        textColor: .humanist(light: 0x322D29, dark: 0xD7DEEF),
        secondaryTextColor: .humanist(light: 0x746D68, dark: 0x8791B0),
        linkColor: .humanist(light: 0x7F4400, dark: 0x798FD4),
        codeForeground: .humanist(light: 0x322D29, dark: 0xE2E2E2),
        codeBackground: .humanist(light: 0xF6E8DD, dark: 0x232C49),
        codeBlockBackground: .humanist(light: 0xF6E8DD, dark: 0x1F2431),
        tableBorderColor: .humanist(light: 0xEBDBCE, dark: 0x2C3860),
        tableHeaderBackground: .humanist(light: 0xF6E8DD, dark: 0x1C2338),
        tableCellBackground: .humanist(light: 0xFFFFFF, dark: 0x000000, lightAlpha: 0.25, darkAlpha: 0.25),
        citationForeground: .humanist(light: 0x8A4B01, dark: 0xE5EBFA),
        citationBackground: .humanist(light: 0xFEE6D4, dark: 0x333A4E),
        quoteBarColor: .humanist(light: 0x746D68, dark: 0x8791B0),
        quoteBackground: .humanist(light: 0xFFFFFF, dark: 0x000000, lightAlpha: 0.25, darkAlpha: 0.25),
        mathColor: .humanist(light: 0x322D29, dark: 0xD7DEEF)
    )
    public static let seriousBusiness = StreamingMarkdownTheme(
        textFont: .system(size: 17, weight: .regular),
        strongTextFont: .system(size: 17, weight: .semibold),
        emphasisTextFont: .system(size: 17, weight: .regular).italic(),
        headingFont: .system(size: 17, weight: .semibold),
        heading1Font: .system(size: 28, weight: .semibold),
        heading2Font: .system(size: 22, weight: .semibold),
        heading3Font: .system(size: 20, weight: .semibold),
        heading4Font: .system(size: 17, weight: .semibold),
        heading5Font: .system(size: 17, weight: .semibold),
        heading6Font: .system(size: 17, weight: .semibold),
        captionFont: .system(size: 13, weight: .regular),
        citationFont: .system(size: 12, weight: .regular),
        tableTextFont: .system(size: 15, weight: .regular),
        tableHeaderFont: .system(size: 15, weight: .semibold),
        codeFont: .system(size: 12, design: .monospaced),
        pageBackground: .humanist(light: 0xFFFFFF, dark: 0x000000),
        surfaceBackground: .humanist(light: 0xFFFFFF, dark: 0x000000),
        controlBackground: .humanist(light: 0xFAFAFA, dark: 0x333333),
        textColor: .humanist(light: 0x242424, dark: 0xFFFFFF),
        secondaryTextColor: .humanist(light: 0x616161, dark: 0xD6D6D6),
        linkColor: .humanist(light: 0x464FEB, dark: 0x7385FF),
        codeForeground: .humanist(light: 0x808080, dark: 0xADADAD),
        codeBackground: .humanist(light: 0xFFFFFF, dark: 0x292929),
        codeBlockBackground: .humanist(light: 0xFAFAFA, dark: 0x333333),
        tableBorderColor: .humanist(light: 0xE0E0E0, dark: 0x3D3D3D),
        tableHeaderBackground: .humanist(light: 0xF5F5F5, dark: 0x141414),
        tableCellBackground: .humanist(light: 0xFFFFFF, dark: 0x000000),
        citationForeground: .humanist(light: 0x616161, dark: 0xD6D6D6),
        citationBackground: .humanist(light: 0xF0F0F0, dark: 0x3D3D3D),
        quoteBarColor: .humanist(light: 0xE0E0E0, dark: 0x3D3D3D),
        quoteBackground: .humanist(light: 0xFFFFFF, dark: 0x000000),
        mathColor: .humanist(light: 0x242424, dark: 0xFFFFFF)
    )
    public static let paperwork = StreamingMarkdownTheme(
        textFont: .system(size: 17, weight: .regular),
        strongTextFont: .system(size: 17, weight: .semibold),
        emphasisTextFont: .system(size: 17, weight: .regular).italic(),
        headingFont: .system(size: 17, weight: .semibold),
        heading1Font: .system(size: 28, weight: .semibold),
        heading2Font: .system(size: 22, weight: .semibold),
        heading3Font: .system(size: 20, weight: .semibold),
        heading4Font: .system(size: 17, weight: .semibold),
        heading5Font: .system(size: 17, weight: .semibold),
        heading6Font: .system(size: 17, weight: .semibold),
        captionFont: .system(size: 13, weight: .regular),
        citationFont: .system(size: 12, weight: .regular),
        tableTextFont: .system(size: 15, weight: .regular),
        tableHeaderFont: .system(size: 15, weight: .semibold),
        codeFont: .system(size: 12, design: .monospaced),
        pageBackground: .humanist(light: 0xFFFFFF, dark: 0x000000),
        surfaceBackground: .humanist(light: 0xFFFFFF, dark: 0x000000),
        controlBackground: .humanist(light: 0xFAFAFA, dark: 0x333333),
        textColor: .humanist(light: 0x242424, dark: 0xFFFFFF),
        secondaryTextColor: .humanist(light: 0x616161, dark: 0xD6D6D6),
        linkColor: .humanist(light: 0x464FEB, dark: 0x96A8FF),
        codeForeground: .humanist(light: 0x808080, dark: 0xADADAD),
        codeBackground: .humanist(light: 0xFFFFFF, dark: 0x292929),
        codeBlockBackground: .humanist(light: 0xFAFAFA, dark: 0x333333),
        tableBorderColor: .humanist(light: 0xB0BEFF, dark: 0x353696),
        tableHeaderBackground: .humanist(light: 0xEBEFFF, dark: 0x27265C),
        tableCellBackground: .humanist(light: 0xFFFFFF, dark: 0x000000),
        citationForeground: .humanist(light: 0x464FEB, dark: 0x96A8FF),
        citationBackground: .humanist(light: 0xEBEFFF, dark: 0x27265C),
        quoteBarColor: .humanist(light: 0xB0BEFF, dark: 0x353696),
        quoteBackground: .humanist(light: 0xFFFFFF, dark: 0x000000),
        mathColor: .humanist(light: 0x242424, dark: 0xFFFFFF)
    )
    public static let tailoredSuit = StreamingMarkdownTheme(
        textFont: .system(size: 17, weight: .regular),
        strongTextFont: .system(size: 17, weight: .semibold),
        emphasisTextFont: .system(size: 17, weight: .regular).italic(),
        headingFont: .system(size: 17, weight: .semibold),
        heading1Font: .system(size: 28, weight: .semibold),
        heading2Font: .system(size: 22, weight: .semibold),
        heading3Font: .system(size: 20, weight: .semibold),
        heading4Font: .system(size: 17, weight: .semibold),
        heading5Font: .system(size: 17, weight: .semibold),
        heading6Font: .system(size: 17, weight: .semibold),
        captionFont: .system(size: 13, weight: .regular),
        citationFont: .system(size: 12, weight: .regular),
        tableTextFont: .system(size: 17, weight: .regular),
        tableHeaderFont: .system(size: 12, weight: .semibold),
        codeFont: .system(size: 12, design: .monospaced),
        pageBackground: .humanist(light: 0xFFFFFF, dark: 0x000000),
        surfaceBackground: .humanist(light: 0xFFFFFF, dark: 0x000000),
        controlBackground: .humanist(light: 0xF0F0F0, dark: 0x3D3D3D),
        textColor: .humanist(light: 0x242424, dark: 0xFFFFFF),
        secondaryTextColor: .humanist(light: 0x808080, dark: 0xADADAD),
        linkColor: .humanist(light: 0x464FEB, dark: 0x7385FF),
        codeForeground: .humanist(light: 0x808080, dark: 0xADADAD),
        codeBackground: .humanist(light: 0xFFFFFF, dark: 0x292929),
        codeBlockBackground: .humanist(light: 0xFAFAFA, dark: 0x333333),
        tableBorderColor: .humanist(light: 0xE0E0E0, dark: 0x3D3D3D),
        tableHeaderBackground: .humanist(light: 0xFAFAFA, dark: 0x333333),
        tableCellBackground: .humanist(light: 0xFAFAFA, dark: 0x333333),
        citationForeground: .humanist(light: 0x616161, dark: 0xD6D6D6),
        citationBackground: .humanist(light: 0xF0F0F0, dark: 0x3D3D3D),
        quoteBarColor: .humanist(light: 0xE0E0E0, dark: 0x3D3D3D),
        quoteBackground: .humanist(light: 0xFFFFFF, dark: 0x000000),
        mathColor: .humanist(light: 0x242424, dark: 0xFFFFFF)
    )
    public static let jazzHands = StreamingMarkdownTheme(
        textFont: .system(size: 17, weight: .regular),
        strongTextFont: .system(size: 17, weight: .semibold),
        emphasisTextFont: .system(size: 17, weight: .regular).italic(),
        headingFont: .system(size: 17, weight: .semibold),
        heading1Font: .system(size: 28, weight: .semibold),
        heading2Font: .system(size: 22, weight: .semibold),
        heading3Font: .system(size: 20, weight: .semibold),
        heading4Font: .system(size: 17, weight: .semibold),
        heading5Font: .system(size: 17, weight: .semibold),
        heading6Font: .system(size: 17, weight: .semibold),
        captionFont: .system(size: 12, weight: .regular),
        citationFont: .system(size: 12, weight: .regular),
        tableTextFont: .system(size: 15, weight: .regular),
        tableHeaderFont: .system(size: 15, weight: .semibold),
        codeFont: .system(size: 15, design: .monospaced),
        pageBackground: .humanist(light: 0xFFFFFF, dark: 0x242424),
        surfaceBackground: .humanist(light: 0xFFFFFF, dark: 0x242424),
        controlBackground: .humanist(light: 0xFCFCFC, dark: 0x292929),
        textColor: .humanist(light: 0x242424, dark: 0xDEDEDE),
        secondaryTextColor: .humanist(light: 0x5D5D5D, dark: 0xAEAEAE),
        linkColor: .humanist(light: 0x242424, dark: 0xDEDEDE),
        codeForeground: .humanist(light: 0x6F6F6F, dark: 0x929292),
        codeBackground: .humanist(light: 0xFCFCFC, dark: 0x292929),
        codeBlockBackground: .humanist(light: 0xF5F5F5, dark: 0x2E2E2E),
        tableBorderColor: .humanist(light: 0xDEDEDE, dark: 0x484848),
        tableHeaderBackground: .clear,
        tableCellBackground: .clear,
        citationForeground: .humanist(light: 0x5D5D5D, dark: 0xAEAEAE),
        citationBackground: .humanist(light: 0xF5F5F5, dark: 0x2E2E2E),
        quoteBarColor: .humanist(light: 0xDEDEDE, dark: 0x484848),
        quoteBackground: .humanist(light: 0xFFFFFF, dark: 0x242424),
        mathColor: .humanist(light: 0x242424, dark: 0xDEDEDE)
    )
    public static let alternativeMan = StreamingMarkdownTheme(
        textFont: .system(size: 16, weight: .regular),
        strongTextFont: .system(size: 16, weight: .semibold),
        emphasisTextFont: .system(size: 16, weight: .regular).italic(),
        headingFont: .system(size: 20, weight: .semibold),
        heading1Font: .system(size: 28, weight: .semibold),
        heading2Font: .system(size: 24, weight: .semibold),
        heading3Font: .system(size: 20, weight: .semibold),
        heading4Font: .system(size: 17, weight: .semibold),
        heading5Font: .system(size: 16, weight: .semibold),
        heading6Font: .system(size: 16, weight: .semibold),
        captionFont: .system(size: 13, weight: .regular),
        citationFont: .system(size: 12, weight: .medium),
        tableTextFont: .system(size: 14, weight: .regular),
        tableHeaderFont: .system(size: 14, weight: .semibold),
        codeFont: .system(size: 14, design: .monospaced),
        pageBackground: .humanist(light: 0xF7F7F8, dark: 0x212121),
        surfaceBackground: .humanist(light: 0xFFFFFF, dark: 0x2F2F2F),
        controlBackground: .humanist(light: 0xF2F2F2, dark: 0x303030),
        textColor: .humanist(light: 0x0D0D0D, dark: 0xECECEC),
        secondaryTextColor: .humanist(light: 0x6E6E80, dark: 0xB4B4B4),
        linkColor: .humanist(light: 0x10A37F, dark: 0x19C37D),
        codeForeground: .humanist(light: 0x0D0D0D, dark: 0xECECEC),
        codeBackground: .humanist(light: 0xECECF1, dark: 0x171717),
        codeBlockBackground: .humanist(light: 0xF7F7F8, dark: 0x171717),
        tableBorderColor: .humanist(light: 0xD9D9E3, dark: 0x444654),
        tableHeaderBackground: .humanist(light: 0xF7F7F8, dark: 0x2A2B32),
        tableCellBackground: .humanist(light: 0xFFFFFF, dark: 0x2F2F2F),
        citationForeground: .humanist(light: 0x087A5B, dark: 0x19C37D),
        citationBackground: .humanist(light: 0xE7F8F2, dark: 0x17372E),
        quoteBarColor: .humanist(light: 0xC5C5D2, dark: 0x565869),
        quoteBackground: .humanist(light: 0xFFFFFF, dark: 0x2F2F2F),
        mathColor: .humanist(light: 0x0D0D0D, dark: 0xECECEC)
    )
    public static let rationalist = StreamingMarkdownTheme(
        textFont: .system(size: 16, weight: .regular, design: .serif),
        strongTextFont: .system(size: 16, weight: .semibold, design: .serif),
        emphasisTextFont: .system(size: 16, weight: .regular, design: .serif).italic(),
        headingFont: .system(size: 20, weight: .semibold, design: .serif),
        heading1Font: .system(size: 28, weight: .semibold, design: .serif),
        heading2Font: .system(size: 24, weight: .semibold, design: .serif),
        heading3Font: .system(size: 20, weight: .semibold, design: .serif),
        heading4Font: .system(size: 17, weight: .semibold, design: .serif),
        heading5Font: .system(size: 16, weight: .semibold, design: .serif),
        heading6Font: .system(size: 16, weight: .semibold, design: .serif),
        captionFont: .system(size: 13, weight: .regular),
        citationFont: .system(size: 12, weight: .medium),
        tableTextFont: .system(size: 14, weight: .regular, design: .serif),
        tableHeaderFont: .system(size: 14, weight: .semibold, design: .serif),
        codeFont: .system(size: 14, design: .monospaced),
        pageBackground: .humanist(light: 0xF8F3EA, dark: 0x191715),
        surfaceBackground: .humanist(light: 0xFFFBF5, dark: 0x24201C),
        controlBackground: .humanist(light: 0xEFE6D8, dark: 0x302A24),
        textColor: .humanist(light: 0x2B2118, dark: 0xF1E8DD),
        secondaryTextColor: .humanist(light: 0x7A6F62, dark: 0xB8AA9A),
        linkColor: .humanist(light: 0xC15F3C, dark: 0xE39A72),
        codeForeground: .humanist(light: 0x2B2118, dark: 0xF1E8DD),
        codeBackground: .humanist(light: 0xF1E7D7, dark: 0x2D2620),
        codeBlockBackground: .humanist(light: 0xF4EADC, dark: 0x2D2620),
        tableBorderColor: .humanist(light: 0xE1D3C3, dark: 0x51453A),
        tableHeaderBackground: .humanist(light: 0xF4EADC, dark: 0x332B24),
        tableCellBackground: .humanist(light: 0xFFFBF5, dark: 0x24201C),
        citationForeground: .humanist(light: 0xA4492F, dark: 0xE39A72),
        citationBackground: .humanist(light: 0xF7E0D2, dark: 0x4A2F24),
        quoteBarColor: .humanist(light: 0xD38B6D, dark: 0x8E604A),
        quoteBackground: .humanist(light: 0xFFFBF5, dark: 0x24201C),
        mathColor: .humanist(light: 0x2B2118, dark: 0xF1E8DD)
    )
}

private extension Color {
    static func humanist(light: UInt32, dark: UInt32, lightAlpha: Double = 1, darkAlpha: Double = 1) -> Color {
        #if canImport(UIKit)
        return Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: dark, alpha: darkAlpha)
                : UIColor(hex: light, alpha: lightAlpha)
        })
        #elseif canImport(AppKit)
        return Color(NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return isDark
                ? NSColor(hex: dark, alpha: darkAlpha)
                : NSColor(hex: light, alpha: lightAlpha)
        })
        #else
        return Color(
            red: Double((light >> 16) & 0xFF) / 255,
            green: Double((light >> 8) & 0xFF) / 255,
            blue: Double(light & 0xFF) / 255,
            opacity: lightAlpha
        )
        #endif
    }
}

#if canImport(UIKit)
private extension UIColor {
    convenience init(hex: UInt32, alpha: Double) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: CGFloat(alpha)
        )
    }
}
#elseif canImport(AppKit)
private extension NSColor {
    convenience init(hex: UInt32, alpha: Double) {
        self.init(
            calibratedRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: CGFloat(alpha)
        )
    }
}
#endif
