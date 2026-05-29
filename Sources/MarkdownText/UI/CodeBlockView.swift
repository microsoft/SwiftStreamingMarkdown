//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation
import HighlightSwift
import SwiftUI

private actor HighlightTaskManager: ObservableObject {
  /// Shared Highlight instance to avoid creating multiple JSContext/HLJS instances.
  /// Each Highlight() creates its own JSContext and evaluates highlight.min.js (~600KB).
  /// When multiple CodeBlockViews render concurrently, N separate JSContexts cause
  /// JavaScriptCore OOM crashes (COPILOT-IOS-3F9C, 3F7Z, 3FSQ).
  private static let sharedHighlight = Highlight()

  private var latestCode: String?
  private var isProcessing = false

  func enqueueCode(_ code: String, completion: @escaping (AttributedString) -> Void) {
    latestCode = code

    if !isProcessing {
      Task {
        await processQueue(completion: completion)
      }
    }
  }

  private func processQueue(completion: @escaping (AttributedString) -> Void) async {
    guard !isProcessing else { return }

    isProcessing = true

    while let codeToProcess = latestCode {
      latestCode = nil

      let css: String = await CodeBlockView.syntaxHighlightingCss
      if let result = try? await Self.sharedHighlight.attributedText(codeToProcess, colors: .custom(css: css, background: "")) {
        await MainActor.run {
          completion(result)
        }
      }
    }

    isProcessing = false
  }
}

public struct CodeBlockView: View {

  let language: String
  let code: String
  let onCodeCopied: (() -> Void)?

  @State var copied: Bool = false
  @State var attributedString: AttributedString?
  @StateObject private var taskManager: HighlightTaskManager = HighlightTaskManager()

  public init(language: String, code: String, onCodeCopied: (() -> Void)? = nil) {
    self.language = language
    self.code = code
    self.onCodeCopied = onCodeCopied
  }

  private func updateAttributedString(code: String) async {
    await taskManager.enqueueCode(code) { newAttributedString in
      self.attributedString = newAttributedString
    }
  }

  @ViewBuilder
  var codeblock: some View {
    ScrollView(.horizontal) {
      HStack(alignment: .top) {
        if #available(iOS 16.1, *) {  // Minimum version for HighlightSwift
          Text(attributedString ?? AttributedString(code))
            .font(Typography.codeTextFonts)
            .transition(.opacity)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          Text(code)
            .font(Typography.codeTextFonts)
            .foregroundStyle(Color.Theme.Component.CodeBlock.Foreground.FunctionParameter)
            .transition(.opacity)
        }
      }

    }.transaction { transaction in
      // The horizontal scrollView resizing animation was causing the code block to animate
      // all janky.
      transaction.animation = nil
    }
    .padding(16)
  }

  public var body: some View {
    VStack(spacing: 0) {
      HStack(alignment: .top) {
        Text(language)
          .font(Typography.smallTextFonts)
          .foregroundStyle(Color.Static.Stone.Stone350)
        Spacer()
        HStack(alignment: .firstTextBaseline, spacing: 6.0) {
          Image("copyIcon14", bundle: .module)
            .renderingMode(.template)
            .foregroundStyle(Color.Static.Stone.Stone350)
          Text(copied ? String.codeCopiedLabel : String.codeCopyLabel)
            .accessibilityAddTraits(.isButton)
            .font(Typography.smallTextFonts)
            .foregroundStyle(Color.Static.Stone.Stone350)
            .onTapGesture {
              copied = true
              UIPasteboard.general.string = code
              if let onCodeCopied {
                onCodeCopied()
              }
            }
        }
      }.frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
          Color.Theme.Component.CodeBlock.Background.Background750
            .clipShape(.rect(
              topLeadingRadius: 20,
              bottomLeadingRadius: 0,
              bottomTrailingRadius: 0,
              topTrailingRadius: 20
            ))
        )
      codeblock
        .fixedSize(horizontal: false, vertical: true)
        .scrollIndicators(.automatic)
        .background(Color.Theme.Component.CodeBlock.Background.Background750
          .clipShape(.rect(
            topLeadingRadius: 0,
            bottomLeadingRadius: 20,
            bottomTrailingRadius: 20,
            topTrailingRadius: 0
          ))
        )
    }.onChange(of: copied, perform: { isCopied in
      if isCopied {
        Task {
          try await Task.sleep(seconds: 3)
          copied = false
        }
      }
    })
    .onChange(of: code, perform: { value in
      Task {
        await updateAttributedString(code: value)
      }
    })
    .onAppear(perform: {
      Task {
        await updateAttributedString(code: code)
      }
    })
  }
}

#if DEBUG

#Preview {
  return LazyVStack {
    Spacer()
    CodeBlockView(language: "Python", code: "import random\n\ndef generate_and_add_numbers(num_numbers):\n    # Generate a list of random numbers random_numbers\n    random_numbers = [random.randint(1, 100) for _ in range(num_numbers)]\n\n\n    # Add the numbers together\n    sum_of_numbers = sum(random_numbers)\n\n    return random_numbers, sum_of_numbers\n\n# Example: Generate 5 random numbers and add them together\nnum_numbers = 5\nrandom_numbers, sum_of_numbers = generate_and_add_numbers(num_numbers)\nprint(f\"Generated numbers: {random_numbers}\")\nprint(f\"Sum of numbers: {sum_of_numbers}\")")
    Spacer()
  }.padding(24)
}

#endif
