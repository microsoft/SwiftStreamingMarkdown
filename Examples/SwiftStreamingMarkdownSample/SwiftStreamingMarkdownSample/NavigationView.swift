//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
import SwiftStreamingMarkdown
import SwiftUI

struct NavigationView: View {
  @State private var demoContent: [Demonstration: String] = [:]
  @State private var isLoading = true

  var body: some View {
    NavigationStack {
      Group {
        if isLoading {
          VStack(spacing: 12) {
            ProgressView()
            Text(verbatim: "Loading demonstrations...")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          List(Demonstration.allCases) { demo in
            NavigationLink(value: demo) {
              VStack(alignment: .leading, spacing: 4) {
                Text(demo.rawValue)
                  .font(.headline)
                Text(demo.subtitle)
                  .font(.subheadline)
                  .foregroundStyle(.secondary)
              }
            }
          }
          .navigationDestination(for: Demonstration.self) { demo in
            DemonstrationView(
              demonstration: demo,
              markdownText: demoContent[demo] ?? "# Unable to load \(demo.rawValue)"
            )
          }
        }
      }
      .navigationTitle("Markdown Demos")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          NavigationLink {
            SettingsView()
          } label: {
            Image(systemName: "gearshape")
          }
          .accessibilityLabel("Settings")
        }
      }
    }
    .task {
      guard isLoading else { return }
      var loaded: [Demonstration: String] = [:]

      for demo in Demonstration.allCases {
        let fixtureFileName = demo.fixtureFileName
        let markdownText: String
        if let url = Bundle.main.url(forResource: fixtureFileName, withExtension: "md"),
           let data = try? Data(contentsOf: url),
           let text = String(data: data, encoding: .utf8) {
          markdownText = text
        } else {
          markdownText = "# Unable to load \(demo.rawValue)\n\nExpected fixture: \(fixtureFileName).md"
        }

        loaded[demo] = markdownText
      }

      demoContent = loaded
      isLoading = false
    }
  }
}
#Preview {
  NavigationView()
}
