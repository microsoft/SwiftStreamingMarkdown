import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

struct TableBlockView: View {
    let table: MarkdownTable
    let configuration: StreamingMarkdownConfiguration
    let actionHandlers: MarkdownActionHandlers
    @State private var isExpanded = false
    @State private var isCopyPressed = false
    @State private var isCopyScaled = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(.horizontal) {
                VStack(alignment: .leading, spacing: 0) {
                    tableRow(table.headers, isHeader: true, rowIndex: 0)
                    ForEach(Array(table.rows.enumerated()), id: \.offset) { index, row in
                        tableRow(row, isHeader: false, rowIndex: index + 1)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: configuration.designSystem.layout.tableCornerRadius)
                        .stroke(configuration.theme.tableBorderColor)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }

            if isExpanded {
                HStack(spacing: 0) {
                    tableCopyButton
                    tableDownloadButton
                }
                .padding(.top, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.opacity)
            }
        }
    }

    private var tableCopyButton: some View {
        Button {
            copy(table.markdownString)
            actionHandlers.onTableExport?(table.exportPayload, .markdown)
            actionHandlers.onEvent?(.tableCopied(format: .markdown))
            isCopyPressed = true
            withAnimation(.easeInOut(duration: 0.2)) {
                isCopyScaled = true
            }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 200_000_000)
                withAnimation(.easeInOut(duration: 0.25)) {
                    isCopyPressed = false
                    isCopyScaled = false
                }
            }
        } label: {
            Image(systemName: isCopyPressed ? "doc.on.doc.fill" : "doc.on.doc")
                .foregroundStyle(configuration.theme.tableActionForeground)
                .frame(width: 20, height: 20)
                .scaleEffect(isCopyScaled ? 1.3 : 1.0)
        }
        .buttonStyle(.plain)
        .frame(width: 32, height: 32)
        .contentShape(Rectangle())
        .accessibilityLabel(isCopyPressed ? "Table copied" : "Copy table")
    }

    private var tableDownloadButton: some View {
        Button {
            copy(table.csvString)
            actionHandlers.onTableExport?(table.exportPayload, .csv)
            actionHandlers.onEvent?(.tableExported(format: .csv))
        } label: {
            Image(systemName: "arrow.down")
                .foregroundStyle(configuration.theme.tableActionForeground)
                .frame(width: 20, height: 20)
                .padding(2)
        }
        .buttonStyle(.plain)
        .frame(width: 32, height: 32)
        .contentShape(Rectangle())
        .accessibilityLabel("Export table as CSV")
    }

    private func tableRow(_ cells: [String], isHeader: Bool, rowIndex: Int) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(cells.enumerated()), id: \.offset) { columnIndex, cell in
                Text(cell)
                    .font(isHeader ? configuration.theme.tableHeaderFont : configuration.theme.tableTextFont)
                    .foregroundStyle(configuration.theme.textColor)
                    .padding(configuration.designSystem.layout.tableCellPadding)
                    .frame(
                        minWidth: configuration.designSystem.layout.tableMinColumnWidth,
                        maxWidth: configuration.designSystem.layout.tableMaxColumnWidth,
                        alignment: .leading
                    )
                    .background(isHeader ? configuration.theme.tableHeaderBackground : configuration.theme.tableCellBackground)
                    .border(configuration.theme.tableBorderColor, width: 0.5)
                    .accessibilityLabel(accessibilityLabel(for: cell, isHeader: isHeader, rowIndex: rowIndex, columnIndex: columnIndex))
            }
        }
    }

    private func accessibilityLabel(for cell: String, isHeader: Bool, rowIndex: Int, columnIndex: Int) -> String {
        if isHeader {
            return "Column \(columnIndex + 1) header, \(cell)"
        }
        let header = table.headers.indices.contains(columnIndex) ? table.headers[columnIndex] : "Column \(columnIndex + 1)"
        return "Row \(rowIndex), \(header), \(cell)"
    }

    private func copy(_ string: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = string
        #endif
    }
}
