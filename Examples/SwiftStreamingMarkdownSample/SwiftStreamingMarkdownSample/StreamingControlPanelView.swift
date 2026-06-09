//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import SwiftUI

struct StreamingControlDrawerView: View {
  @Binding var isPresented: Bool
  @ObservedObject var playback: StreamingPlaybackController
  @ObservedObject var performanceMetrics: StreamingPerformanceModel
  @ObservedObject var listener: LoggingMarkdownListener

  let isStreaming: Bool

  var body: some View {
    VStack(spacing: 0) {
      if isPresented {
        StreamingControlPanelView(
          isPresented: $isPresented,
          playback: playback,
          performanceMetrics: performanceMetrics,
          listener: listener,
          isStreaming: isStreaming
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
      } else {
        Button {
          withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            isPresented = true
          }
        } label: {
          Image(systemName: "chevron.up")
            .font(.headline.weight(.semibold))
            .frame(width: 96, height: 44)
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
        .background(.regularMaterial, in: Capsule(style: .continuous))
        .overlay {
          Capsule(style: .continuous)
            .stroke(Color.primary.opacity(0.08))
        }
        .padding(.bottom, 8)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .accessibilityLabel("Show streaming controls")
      }
    }
    .animation(.spring(response: 0.28, dampingFraction: 0.86), value: isPresented)
    .gesture(
      DragGesture(minimumDistance: 16)
        .onEnded { value in
          guard abs(value.translation.height) > 28 else { return }
          withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            isPresented = value.translation.height < 0
          }
        }
    )
  }
}

struct StreamingControlPanelView: View {
  @Binding var isPresented: Bool
  @ObservedObject var playback: StreamingPlaybackController
  @ObservedObject var performanceMetrics: StreamingPerformanceModel
  @ObservedObject var listener: LoggingMarkdownListener

  let isStreaming: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Button {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
          isPresented = false
        }
      } label: {
        Capsule(style: .continuous)
          .fill(Color.secondary.opacity(0.35))
          .frame(width: 42, height: 5)
          .frame(maxWidth: .infinity)
          .frame(height: 24)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Hide streaming controls")

      HStack(spacing: 0) { controls }
        .frame(maxWidth: .infinity)

      VStack(alignment: .leading, spacing: 8) {
        ProgressView(value: performanceMetrics.progress)

        LazyVGrid(columns: columns, alignment: .center, spacing: 8) {
          metric("Chars", "\(performanceMetrics.streamedCharacters)/\(performanceMetrics.totalCharacters)")
          metric("Chunks", "\(performanceMetrics.chunkCount)")
          metric("Renders", "\(performanceMetrics.renderCount)")
          metric("Elapsed", elapsedText)
          metric("Chars/sec", numberText(performanceMetrics.charactersPerSecond))
          metric("Chunks/sec", numberText(performanceMetrics.chunksPerSecond))
          metric("Render lag", latencyText)
          metric("State", stateText)
        }
        .frame(maxWidth: .infinity)
      }
    }
    .font(.subheadline)
    .padding(.horizontal, 14)
    .padding(.top, 6)
    .padding(.bottom, 12)
    .safeAreaPadding(.bottom, 8)
    .frame(maxWidth: .infinity)
    .background {
      UnevenRoundedRectangle(
        topLeadingRadius: 18,
        bottomLeadingRadius: 0,
        bottomTrailingRadius: 0,
        topTrailingRadius: 18,
        style: .continuous
      )
      .fill(.regularMaterial)
      .ignoresSafeArea(edges: .bottom)
    }
    .padding(.horizontal, 0)
    .padding(.top, 8)
    .padding(.bottom, 0)
  }

  private var controls: some View {
    Group {
      playbackControls

      controlDivider

      followControl

      controlDivider

      speedControls
    }
  }

  private var playbackControls: some View {
    HStack(spacing: 4) {
      Button {
        playback.replay()
      } label: {
        controlIcon("arrow.counterclockwise", isSelected: false)
      }
      .buttonStyle(.plain)
      .frame(maxWidth: .infinity)
      .accessibilityLabel("Replay stream")

      Button {
        playback.togglePlayback()
      } label: {
        controlIcon(playback.isPlaying ? "pause.fill" : "play.fill", isSelected: playback.isPlaying)
      }
      .buttonStyle(.plain)
      .frame(maxWidth: .infinity)
      .disabled(!isStreaming || performanceMetrics.isComplete)
      .accessibilityLabel(playback.isPlaying ? "Pause stream" : "Play stream")

      Button {
        playback.fastForward()
      } label: {
        controlIcon("forward.end.fill", isSelected: false)
      }
      .buttonStyle(.plain)
      .frame(maxWidth: .infinity)
      .disabled(!isStreaming || performanceMetrics.isComplete)
      .accessibilityLabel("Fast forward stream")
    }
    .frame(maxWidth: .infinity)
  }

  private var followControl: some View {
    HStack(spacing: 0) {
      Button {
        listener.toggleFollowScrolling()
      } label: {
        controlIcon("arrow.down", isSelected: listener.followsStreamingMarkdown)
      }
      .buttonStyle(.plain)
      .frame(maxWidth: .infinity)
      .disabled(!isStreaming)
      .accessibilityLabel(listener.followsStreamingMarkdown ? "Disable follow scrolling" : "Enable follow scrolling")
    }
    .frame(width: 48)
  }

  private var speedControls: some View {
    HStack(spacing: 4) {
      speedButton(.slow, systemImage: "tortoise.fill")
      speedButton(.normal, systemImage: "figure.walk")
      speedButton(.fast, systemImage: "hare.fill")
    }
    .frame(maxWidth: .infinity)
  }

  private var controlDivider: some View {
    Divider()
      .frame(width: 1, height: 24)
      .padding(.horizontal, 10)
  }

  private var columns: [GridItem] {
    [
      GridItem(.flexible(), spacing: 8),
      GridItem(.flexible(), spacing: 8),
      GridItem(.flexible(), spacing: 8),
      GridItem(.flexible(), spacing: 8)
    ]
  }

  private var elapsedText: String {
    "\(numberText(performanceMetrics.elapsedTime))s"
  }

  private var latencyText: String {
    guard let lastRenderLatency = performanceMetrics.lastRenderLatency else {
      return "—"
    }
    return "\(numberText(lastRenderLatency * 1_000))ms"
  }

  private var stateText: String {
    if performanceMetrics.isComplete {
      return "Done"
    }

    if isStreaming {
      return playback.isPlaying ? "Playing" : "Paused"
    }

    return "Static"
  }

  private func speedButton(_ speed: StreamingSpeed, systemImage: String) -> some View {
    Button {
      playback.speed = speed
    } label: {
      controlIcon(systemImage, isSelected: playback.speed == speed)
    }
    .buttonStyle(.plain)
    .frame(maxWidth: .infinity)
    .disabled(!isStreaming)
    .accessibilityLabel("\(speed.displayName) streaming speed")
  }

  private func controlIcon(_ systemImage: String, isSelected: Bool) -> some View {
    Image(systemName: systemImage)
      .font(.caption.weight(.semibold))
      .frame(width: 44, height: 44)
      .foregroundStyle(isSelected ? Color.white : Color.primary)
      .background(controlBackground(isSelected: isSelected))
  }

  private func controlBackground(isSelected: Bool) -> some View {
    Circle()
      .fill(isSelected ? Color.accentColor : Color.primary.opacity(0.08))
  }

  private func metric(_ title: String, _ value: String) -> some View {
    VStack(alignment: .center, spacing: 2) {
      Text(title)
        .font(.caption2)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
      Text(value)
        .font(.caption.monospacedDigit())
        .foregroundStyle(.primary)
        .lineLimit(1)
        .minimumScaleFactor(0.75)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, alignment: .center)
  }

  private func numberText(_ value: Double) -> String {
    if value >= 100 {
      return String(format: "%.0f", value)
    }

    if value >= 10 {
      return String(format: "%.1f", value)
    }

    return String(format: "%.2f", value)
  }
}
