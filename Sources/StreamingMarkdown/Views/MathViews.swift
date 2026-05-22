import SwiftUI

#if canImport(iosMath) && canImport(UIKit)
import iosMath
import UIKit

public struct BlockMathView: UIViewRepresentable {
    public let latex: String
    public let color: Color
    public let pointSize: CGFloat

    public init(latex: String, color: Color = .primary, pointSize: CGFloat = UIFont.preferredFont(forTextStyle: .body).pointSize) {
        self.latex = latex
        self.color = color
        self.pointSize = pointSize
    }

    public func makeUIView(context: Context) -> UIStackView {
        makeMathStack(labelMode: MTMathUILabelMode(rawValue: 0)!)
    }

    public func updateUIView(_ uiView: UIStackView, context: Context) {
        updateMathStack(uiView, latex: latex, color: color, pointSize: pointSize)
    }

    public func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIStackView, context: Context) -> CGSize? {
        updateMathStack(uiView, latex: latex, color: color, pointSize: pointSize)
        return measuredMathStackSize(uiView, latex: latex, pointSize: pointSize, proposal: proposal)
    }
}

struct InlineMathView: UIViewRepresentable {
    let latex: String
    let color: Color

    func makeUIView(context: Context) -> UIStackView {
        makeMathStack(labelMode: MTMathUILabelMode(rawValue: 1)!)
    }

    func updateUIView(_ uiView: UIStackView, context: Context) {
        updateMathStack(uiView, latex: latex, color: color, pointSize: UIFont.preferredFont(forTextStyle: .body).pointSize)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIStackView, context: Context) -> CGSize? {
        let pointSize = UIFont.preferredFont(forTextStyle: .body).pointSize
        updateMathStack(uiView, latex: latex, color: color, pointSize: pointSize)
        return measuredMathStackSize(uiView, latex: latex, pointSize: pointSize, proposal: proposal)
    }
}

private func makeMathStack(labelMode: MTMathUILabelMode) -> UIStackView {
    let mathLabel = MTMathUILabel()
    mathLabel.displayErrorInline = false
    mathLabel.labelMode = labelMode
    mathLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)

    let fallbackLabel = UILabel()
    fallbackLabel.numberOfLines = 0
    fallbackLabel.isHidden = true
    fallbackLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)

    let stack = UIStackView(arrangedSubviews: [mathLabel, fallbackLabel])
    stack.axis = .vertical
    stack.alignment = .leading
    stack.setContentHuggingPriority(.required, for: .horizontal)
    stack.setContentHuggingPriority(.required, for: .vertical)
    return stack
}

private func updateMathStack(_ stack: UIStackView, latex: String, color: Color, pointSize: CGFloat) {
    guard let mathLabel = stack.arrangedSubviews.first as? MTMathUILabel,
          let fallbackLabel = stack.arrangedSubviews.dropFirst().first as? UILabel else {
        return
    }

    mathLabel.textColor = UIColor(color)
    mathLabel.fontSize = pointSize
    mathLabel.latex = latex

    fallbackLabel.textColor = UIColor(color)
    fallbackLabel.font = .italicSystemFont(ofSize: pointSize)
    fallbackLabel.text = latex

    let shouldFallback = mathLabel.error != nil
    mathLabel.isHidden = shouldFallback
    fallbackLabel.isHidden = !shouldFallback

    mathLabel.invalidateIntrinsicContentSize()
    fallbackLabel.invalidateIntrinsicContentSize()
    stack.invalidateIntrinsicContentSize()
    stack.setNeedsLayout()
    stack.layoutIfNeeded()
}

private func measuredMathStackSize(_ stack: UIStackView, latex: String, pointSize: CGFloat, proposal: ProposedViewSize) -> CGSize {
    let targetWidth = proposal.width ?? UIView.layoutFittingCompressedSize.width
    let targetSize = CGSize(width: targetWidth, height: UIView.layoutFittingCompressedSize.height)
    let fittingSize = stack.systemLayoutSizeFitting(
        targetSize,
        withHorizontalFittingPriority: proposal.width == nil ? .fittingSizeLevel : .required,
        verticalFittingPriority: .fittingSizeLevel
    )

    if fittingSize.width > 0, fittingSize.height > 0 {
        return CGSize(width: fittingSize.width.rounded(.up), height: fittingSize.height.rounded(.up) + 1)
    }

    let fallbackSize = (latex as NSString).size(withAttributes: [
        .font: UIFont.italicSystemFont(ofSize: pointSize)
    ])
    return CGSize(width: fallbackSize.width.rounded(.up), height: fallbackSize.height.rounded(.up) + 1)
}
#else
public struct BlockMathView: View {
    public let latex: String
    public let color: Color
    public let pointSize: CGFloat

    public init(latex: String, color: Color = .primary, pointSize: CGFloat = 17) {
        self.latex = latex
        self.color = color
        self.pointSize = pointSize
    }

    public var body: some View {
        Text(latex)
            .font(.system(size: pointSize, design: .serif).italic())
            .foregroundStyle(color)
    }
}

struct InlineMathView: View {
    let latex: String
    let color: Color

    var body: some View {
        Text(latex)
            .italic()
            .foregroundStyle(color)
    }
}
#endif
