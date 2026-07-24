//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
import HighlightSwift
import SwiftUI

struct CodeBlockView: View {

  @Environment(\.markdownConfig) private var config: MarkdownRenderConfig
  @Environment(\.colorScheme) private var colorScheme

  let language: String
  let code: String
  let onCodeCopied: (() -> Void)?

  @State var copied: Bool = false
  @State var attributedString: AttributedString?
  @StateObject private var taskManager: HighlightTaskManager = HighlightTaskManager()

  init(language: String, code: String, onCodeCopied: (() -> Void)? = nil) {
    self.language = language
    self.code = code
    self.onCodeCopied = onCodeCopied
  }

  private func updateAttributedString(code: String, scheme: ColorScheme) async {
    let colors = config.codeBlockConfig.theme.highlightColors(for: scheme)
    await taskManager.enqueueCode(code, colors: colors) { newAttributedString in
      self.attributedString = newAttributedString
    }
  }

  private var backgroundColor: Color? {
    config.codeBlockConfig.backgroundColor
  }

  private var foregroundColor: Color {
    config.codeBlockConfig.foregroundColor ?? Color.Static.Stone.Stone350
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

  var body: some View {
    VStack(spacing: 0) {
      HStack(alignment: .top) {
        Text(language)
          .font(Typography.smallTextFonts)
          .foregroundStyle(foregroundColor)
        Spacer()
        HStack(alignment: .firstTextBaseline, spacing: 6.0) {
          Image("copyIcon14", bundle: .module)
            .renderingMode(.template)
            .foregroundStyle(foregroundColor)
          Text(copied ? String.codeCopiedLabel : String.codeCopyLabel)
            .accessibilityAddTraits(.isButton)
            .font(Typography.smallTextFonts)
            .foregroundStyle(foregroundColor)
            .onTapGesture {
              copied = true
              #if canImport(UIKit)
              UIPasteboard.general.string = code
              #elseif canImport(AppKit)
              NSPasteboard.general.clearContents()
              NSPasteboard.general.setString(code, forType: .string)
              #endif
              if let onCodeCopied {
                onCodeCopied()
              }
            }
        }
      }.frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
          backgroundColor
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
        .if(backgroundColor != nil, content: { view in
          let color = backgroundColor ?? Color.clear
          return view.background(color
            .clipShape(.rect(
              topLeadingRadius: 0,
              bottomLeadingRadius: 20,
              bottomTrailingRadius: 20,
              topTrailingRadius: 0
            ))
          )
        })
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
        await updateAttributedString(code: value, scheme: colorScheme)
      }
    })
    .onChange(of: colorScheme, perform: { newValue in
      Task {
        await updateAttributedString(code: code, scheme: newValue)
      }
    })
    .onChange(of: config, perform: { _ in
      Task {
        await updateAttributedString(code: code, scheme: colorScheme)
      }
    })
    .onAppear(perform: {
      Task {
        await updateAttributedString(code: code, scheme: colorScheme)
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
