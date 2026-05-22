import Foundation
import StreamingMarkdown
import UIKit

@MainActor
final class StreamingDemoModel: ObservableObject {
    @Published private(set) var streamedText = ""
    @Published private(set) var eventLog: [String] = []
    @Published var selectedFixture: StreamingMarkdownFixture = StreamingMarkdownFixtures.mixed {
        didSet { restart() }
    }
    @Published private(set) var isPaused = false
    @Published private(set) var isStreaming = false
    @Published var speed: DemoStreamingSpeed = .normal {
        didSet {
            guard oldValue != speed else { return }
            log("Speed: \(speed.title)")
            restart()
        }
    }
    @Published private(set) var metrics = DemoPerformanceMetrics()

    var showsPlayControl: Bool {
        isPaused || !isStreaming
    }

    private var streamTask: Task<Void, Never>?
    private var frameSampler: DemoFrameSampler?
    private var offset = 0
    private var streamStartTime: Date?

    deinit {
        streamTask?.cancel()
        frameSampler?.stop()
    }

    func start() {
        guard streamTask == nil, !isComplete else { return }
        if streamStartTime == nil {
            resetMetrics()
        }
        isStreaming = true
        frameSampler?.start()
        streamTask = Task { [weak self] in
            while let self, !Task.isCancelled {
                if self.isComplete {
                    self.stopStreaming()
                    break
                }
                if !self.isPaused {
                    self.appendNextChunk()
                }
                try? await Task.sleep(nanoseconds: self.speed.delayNanoseconds)
            }
        }
    }

    func pauseOrResume() {
        guard isStreaming else {
            restart()
            return
        }
        isPaused.toggle()
        if isPaused {
            frameSampler?.stop()
        } else {
            frameSampler?.start()
        }
        log(isPaused ? "Paused stream" : "Resumed stream")
    }

    func restart() {
        streamTask?.cancel()
        streamTask = nil
        frameSampler?.stop()
        streamedText = ""
        offset = 0
        resetMetrics()
        isPaused = false
        isStreaming = false
        log("Restarted \(selectedFixture.title)")
        start()
    }

    func jumpToEnd() {
        streamedText = selectedFixture.text
        offset = selectedFixture.text.count
        streamTask?.cancel()
        streamTask = nil
        frameSampler?.stop()
        metrics.chunksEmitted = metrics.totalChunks
        updateElapsed()
        isPaused = false
        isStreaming = false
        log("Jumped to final content")
    }

    func recordRenderPass() {
        metrics.renderPassCount += 1
    }

    func log(_ message: String) {
        eventLog.insert(message, at: 0)
        eventLog = Array(eventLog.prefix(12))
    }

    private var isComplete: Bool {
        offset >= selectedFixture.text.count
    }

    private func appendNextChunk() {
        let text = selectedFixture.text
        guard offset < text.count else { return }
        let now = Date()
        if metrics.timeToFirstRenderMilliseconds == nil, let streamStartTime {
            metrics.timeToFirstRenderMilliseconds = now.timeIntervalSince(streamStartTime) * 1_000
        }

        let nextOffset = min(offset + speed.chunkSize, text.count)
        let endIndex = text.index(text.startIndex, offsetBy: nextOffset)
        streamedText = String(text[..<endIndex])
        offset = nextOffset
        metrics.chunksEmitted += 1
        updateElapsed(now)
    }

    private func stopStreaming() {
        streamTask?.cancel()
        streamTask = nil
        frameSampler?.stop()
        updateElapsed()
        isPaused = false
        isStreaming = false
        log("Finished stream")
    }

    private func resetMetrics() {
        streamStartTime = Date()
        metrics = DemoPerformanceMetrics(totalChunks: totalChunks)
        frameSampler?.stop()
        frameSampler = DemoFrameSampler { [weak self] duration, dropped in
            guard let self else { return }
            self.metrics.averageFrameMilliseconds = self.metrics.averageFrameMilliseconds == 0
                ? duration
                : (self.metrics.averageFrameMilliseconds * 0.9) + (duration * 0.1)
            self.metrics.maxFrameMilliseconds = max(self.metrics.maxFrameMilliseconds, duration)
            self.metrics.droppedFrames += dropped
        }
    }

    private var totalChunks: Int {
        guard !selectedFixture.text.isEmpty else { return 0 }
        return Int(ceil(Double(selectedFixture.text.count) / Double(speed.chunkSize)))
    }

    private func updateElapsed(_ now: Date = Date()) {
        guard let streamStartTime else { return }
        metrics.totalMilliseconds = now.timeIntervalSince(streamStartTime) * 1_000
    }
}

enum DemoStreamingSpeed: String, CaseIterable, Identifiable {
    case fast
    case normal
    case slow

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fast: "Fast"
        case .normal: "Normal"
        case .slow: "Slow"
        }
    }

    var symbolName: String {
        switch self {
        case .fast: "hare.fill"
        case .normal: "figure.walk"
        case .slow: "tortoise.fill"
        }
    }

    var chunkSize: Int {
        switch self {
        case .fast: 28
        case .normal: 12
        case .slow: 6
        }
    }

    var delayNanoseconds: UInt64 {
        switch self {
        case .fast: 45_000_000
        case .normal: 120_000_000
        case .slow: 260_000_000
        }
    }
}

struct DemoPerformanceMetrics {
    var timeToFirstRenderMilliseconds: Double?
    var totalMilliseconds: Double = 0
    var chunksEmitted: Int = 0
    var totalChunks: Int = 0
    var averageFrameMilliseconds: Double = 0
    var maxFrameMilliseconds: Double = 0
    var droppedFrames: Int = 0
    var renderPassCount: Int = 0
}

private final class DemoFrameSampler: NSObject {
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval?
    private let onFrame: @MainActor (Double, Int) -> Void

    init(onFrame: @escaping @MainActor (Double, Int) -> Void) {
        self.onFrame = onFrame
    }

    func start() {
        guard displayLink == nil else { return }
        lastTimestamp = nil
        let link = CADisplayLink(target: self, selector: #selector(handleFrame(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        lastTimestamp = nil
    }

    @objc private func handleFrame(_ link: CADisplayLink) {
        defer { lastTimestamp = link.timestamp }
        guard let lastTimestamp else { return }
        let duration = (link.timestamp - lastTimestamp) * 1_000
        let expected = link.duration * 1_000
        let dropped = expected > 0 ? max(0, Int((duration / expected).rounded(.down)) - 1) : 0
        Task { @MainActor in
            onFrame(duration, dropped)
        }
    }
}
