import StreamingMarkdown
import SwiftUI

struct ContentView: View {
    @StateObject private var model = StreamingDemoModel()
    @State private var selectedDesignSystem: DemoDesignSystem = .humanist
    @State private var selectedAppearance: DemoAppearance = .system
    @State private var selectedCitationPresentation: DemoCitationPresentation = .inlinePills
    @State private var selectedAnimationPolicy: DemoAnimationPolicy = .automatic
    @State private var enablesSpeculativeRewrites = true
    @State private var showsRewriteDiagnostics = true
    @State private var isSettingsPresented = false
    private let rendererAnchorID = "renderer-bottom"

    var body: some View {
        NavigationStack {
            ZStack {
                designSystem.theme.pageBackground.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 8) {
                    playbackControls
                    playbackMetricsStrip
                    rendererCard
                }
                .padding(.horizontal, 10)
                .padding(.top, 6)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                eventLog
            }
            .overlay(alignment: .bottomTrailing) {
                settingsFloatingButton
                    .padding(.trailing, 16)
                    .padding(.bottom, 16)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $isSettingsPresented) {
            settingsModal
                .preferredColorScheme(selectedAppearance.colorScheme)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .task { model.start() }
        .preferredColorScheme(selectedAppearance.colorScheme)
    }

    private var fixtureMenu: some View {
        Menu {
            ForEach(StreamingMarkdownFixtures.all) { fixture in
                Button(fixture.title) {
                    model.selectedFixture = fixture
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "doc.text")
                    .layoutPriority(1)
                Text(model.selectedFixture.title)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.semibold))
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(designSystem.theme.linkColor)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Select fixture, current fixture \(model.selectedFixture.title)")
    }

    private var settingsFloatingButton: some View {
        Button {
            isSettingsPresented = true
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(designSystem.theme.pageBackground)
                .frame(width: 52, height: 52)
                .background(designSystem.theme.linkColor, in: Circle())
                .shadow(color: .black.opacity(0.22), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open preview settings")
    }

    private var settingsModal: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    settingsSection(title: "Design system") {
                        designSystemGrid
                    }

                    settingsSection(title: "Appearance") {
                        Picker("Appearance", selection: $selectedAppearance) {
                            ForEach(DemoAppearance.allCases) { item in
                                Text(item.title).tag(item)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    settingsSection(title: "Citations") {
                        Picker("Citation presentation", selection: $selectedCitationPresentation) {
                            ForEach(DemoCitationPresentation.allCases) { item in
                                Text(item.title).tag(item)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    settingsSection(title: "Rendering") {
                        Picker("Motion", selection: $selectedAnimationPolicy) {
                            ForEach(DemoAnimationPolicy.allCases) { item in
                                Text(item.title).tag(item)
                            }
                        }
                        .pickerStyle(.segmented)

                        Toggle("Speculative rewrites", isOn: $enablesSpeculativeRewrites)
                        Toggle("Rewrite diagnostics", isOn: $showsRewriteDiagnostics)
                    }
                }
                .padding(18)
            }
            .background(designSystem.theme.pageBackground.ignoresSafeArea())
            .navigationTitle("Preview settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        isSettingsPresented = false
                    }
                }
            }
        }
    }

    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(designSystem.theme.secondaryTextColor)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(designSystem.theme.surfaceBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(designSystem.theme.tableBorderColor.opacity(0.55))
        }
    }

    private var designSystemGrid: some View {
        VStack(spacing: 6) {
            ForEach(DemoDesignSystem.gridRows, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(row) { item in
                        Button {
                            selectedDesignSystem = item
                        } label: {
                            Text(item.title)
                                .font(.caption2.weight(selectedDesignSystem == item ? .semibold : .regular))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 6)
                                .foregroundStyle(selectedDesignSystem == item ? designSystem.theme.linkColor : designSystem.theme.textColor)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(selectedDesignSystem == item ? designSystem.theme.linkColor.opacity(0.14) : designSystem.theme.surfaceBackground.opacity(0.7))
                                )
                                .overlay {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(selectedDesignSystem == item ? designSystem.theme.linkColor : designSystem.theme.tableBorderColor.opacity(0.55))
                                }
                        }
                        .buttonStyle(.plain)
                    }

                    ForEach(0..<max(0, 3 - row.count), id: \.self) { _ in
                        Color.clear
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private var rendererCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    StreamingMarkdownView(
                        text: model.streamedText,
                        configuration: StreamingMarkdownConfiguration(
                            parseOptions: .init(enablesSpeculativeRewrites: enablesSpeculativeRewrites),
                            designSystem: designSystem,
                            citationPresentation: selectedCitationPresentation.presentation,
                            animationPolicy: selectedAnimationPolicy.policy
                        ),
                        showsRewriteDiagnostics: showsRewriteDiagnostics,
                        onLinkTap: { model.log("Link: \($0.absoluteString)") },
                        onCitationTap: { model.log("Citation: \($0.accessibilityLabel)") },
                        onCodeCopy: { code, language in model.log("Copied \(language ?? "plain") code (\(code.count) chars)") },
                        onTableExport: { payload, format in
                            model.log("Table \(format.rawValue): \(payload.value(for: format).count) chars")
                        }
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Color.clear
                        .frame(height: 1)
                        .id(rendererAnchorID)
                }
                .onChange(of: model.streamedText) { _ in
                    model.recordRenderPass()
                    scrollRendererToBottom(proxy)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(designSystem.theme.surfaceBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(designSystem.theme.tableBorderColor.opacity(0.65))
        }
    }

    private var eventLog: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("Events", systemImage: "list.bullet.rectangle")
                    .font(.caption.bold())
                Spacer()
                Text("\(model.eventLog.count)")
                    .font(.caption2)
                    .foregroundStyle(designSystem.theme.secondaryTextColor)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 3) {
                    if model.eventLog.isEmpty {
                        Text("Tap links, citations, code, or tables to see callbacks.")
                            .font(.caption2)
                            .foregroundStyle(designSystem.theme.secondaryTextColor)
                    } else {
                        ForEach(Array(model.eventLog.enumerated()), id: \.offset) { _, event in
                            Text(event)
                                .font(.caption2)
                                .lineLimit(1)
                                .foregroundStyle(designSystem.theme.secondaryTextColor)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .frame(maxHeight: 36)
            .scrollIndicators(.hidden)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(designSystem.theme.tableBorderColor.opacity(0.45))
        }
    }

    private var playbackControls: some View {
        HStack(spacing: 8) {
            fixtureMenu
                .frame(minWidth: 28, maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)

            controlDivider

            HStack(spacing: 12) {
                Button {
                    model.pauseOrResume()
                } label: {
                    Image(systemName: model.showsPlayControl ? "play.fill" : "pause.fill")
                }
                .accessibilityLabel(model.showsPlayControl ? "Resume" : "Pause")

                Button {
                    model.restart()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .accessibilityLabel("Restart")

                Button {
                    model.jumpToEnd()
                } label: {
                    Image(systemName: "forward.end.fill")
                }
                .accessibilityLabel("Show final content")
            }

            controlDivider

            HStack(spacing: 12) {
                ForEach(DemoStreamingSpeed.allCases) { speed in
                    Button {
                        model.speed = speed
                    } label: {
                        Image(systemName: speed.symbolName)
                            .font(.subheadline.weight(model.speed == speed ? .semibold : .regular))
                            .foregroundStyle(model.speed == speed ? designSystem.theme.linkColor : designSystem.theme.secondaryTextColor)
                    }
                    .accessibilityLabel("\(speed.title) streaming speed")
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(designSystem.theme.tableBorderColor.opacity(0.35))
        }
    }

    private var controlDivider: some View {
        Rectangle()
            .fill(designSystem.theme.secondaryTextColor.opacity(0.75))
            .frame(width: 1, height: 22)
    }

    private var playbackMetricsStrip: some View {
        HStack(spacing: 4) {
            metricTile(value: wholeMilliseconds(model.metrics.timeToFirstRenderMilliseconds ?? 0), label: "TTFR")
            metricTile(value: elapsedTime(model.metrics.totalMilliseconds), label: "Total")
            metricTile(value: "\(model.metrics.chunksEmitted)/\(model.metrics.totalChunks)", label: "Chunks")
            metricTile(value: frameMilliseconds(model.metrics.averageFrameMilliseconds), label: "Avg Frame")
            metricTile(value: wholeMilliseconds(model.metrics.maxFrameMilliseconds), label: "Max Frame")
            metricTile(value: "\(model.metrics.droppedFrames)", label: "Dropped")
            metricTile(value: "\(model.metrics.renderPassCount)", label: "Render Passes")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(designSystem.theme.tableBorderColor.opacity(0.35))
        }
    }

    private func metricTile(value: String, label: String) -> some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                .foregroundStyle(designSystem.theme.textColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption2)
                .foregroundStyle(designSystem.theme.secondaryTextColor)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity)
    }

    private func wholeMilliseconds(_ milliseconds: Double) -> String {
        "\(Int(milliseconds.rounded()))ms"
    }

    private func elapsedTime(_ milliseconds: Double) -> String {
        milliseconds < 1_000 ? wholeMilliseconds(milliseconds) : String(format: "%.1fs", milliseconds / 1_000)
    }

    private func frameMilliseconds(_ milliseconds: Double) -> String {
        milliseconds == 0 ? "0ms" : String(format: "%.1fms", milliseconds)
    }

    private var designSystem: StreamingMarkdownDesignSystem {
        selectedDesignSystem.designSystem
    }

    private func scrollRendererToBottom(_ proxy: ScrollViewProxy) {
        guard !model.streamedText.isEmpty else { return }
        withAnimation(.easeOut(duration: 0.18)) {
            proxy.scrollTo(rendererAnchorID, anchor: .bottom)
        }
    }
}

private enum DemoDesignSystem: String, CaseIterable, Identifiable {
    case `default`
    case systemDefault
    case humanist
    case seriousBusiness
    case paperwork
    case tailoredSuit
    case jazzHands
    case alternativeMan
    case rationalist

    var id: String { rawValue }

    var title: String {
        switch self {
        case .default: "SF Pro"
        case .systemDefault: "System Default"
        case .humanist: "Humanist"
        case .seriousBusiness: "Serious Business"
        case .paperwork: "Paperwork"
        case .tailoredSuit: "Tailored Suit"
        case .jazzHands: "Jazz Hands"
        case .alternativeMan: "Alternative Man"
        case .rationalist: "Rationalist"
        }
    }

    var designSystem: StreamingMarkdownDesignSystem {
        switch self {
        case .default: .default
        case .systemDefault: .systemDefault
        case .humanist: .humanist
        case .seriousBusiness: .seriousBusiness
        case .paperwork: .paperwork
        case .tailoredSuit: .tailoredSuit
        case .jazzHands: .jazzHands
        case .alternativeMan: .alternativeMan
        case .rationalist: .rationalist
        }
    }

    static var gridRows: [[DemoDesignSystem]] {
        stride(from: 0, to: allCases.count, by: 3).map { start in
            Array(allCases[start..<Swift.min(start + 3, allCases.count)])
        }
    }
}

private enum DemoAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

private enum DemoCitationPresentation: String, CaseIterable, Identifiable {
    case inlinePills
    case collapsed
    #if canImport(UIKit)
    case uikitPills
    #endif

    var id: String { rawValue }

    var title: String {
        switch self {
        case .inlinePills: "Inline"
        case .collapsed: "Collapsed"
        #if canImport(UIKit)
        case .uikitPills: "UIKit"
        #endif
        }
    }

    var presentation: CitationPresentationStyle {
        switch self {
        case .inlinePills: .inlinePills
        case .collapsed: .collapsed(maxVisible: 1)
        #if canImport(UIKit)
        case .uikitPills: .uikitPills
        #endif
        }
    }
}

private enum DemoAnimationPolicy: String, CaseIterable, Identifiable {
    case automatic
    case enabled
    case disabled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .automatic: "Auto"
        case .enabled: "On"
        case .disabled: "Off"
        }
    }

    var policy: StreamingMarkdownAnimationPolicy {
        switch self {
        case .automatic: .automatic
        case .enabled: .enabled
        case .disabled: .disabled
        }
    }
}
