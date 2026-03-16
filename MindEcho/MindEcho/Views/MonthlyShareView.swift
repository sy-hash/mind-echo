import MindEchoCore
import SwiftData
import SwiftUI

struct MonthlyShareView: View {
    @State private var viewModel: MonthlyShareViewModel
    @State private var shareItems: [Any]?
    @Environment(\.dismiss) private var dismiss

    init(modelContext: ModelContext) {
        _viewModel = State(initialValue: MonthlyShareViewModel(modelContext: modelContext))
    }

    var body: some View {
        NavigationStack {
            List {
                monthSection
                formatSection
            }
            .navigationTitle("月間共有")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityIdentifier("monthlyShare.closeButton")
                }
            }
            .safeAreaInset(edge: .bottom) {
                bottomBar
            }
            .onAppear {
                viewModel.fetchAvailableMonths()
            }
            .sheet(
                isPresented: Binding(
                    get: { shareItems != nil },
                    set: { if !$0 { shareItems = nil } }
                )
            ) {
                if let items = shareItems {
                    ShareSheet(activityItems: items)
                }
            }
            .onChange(of: viewModel.exportState) { _, newState in
                if case .done(let urls) = newState {
                    shareItems = urls
                    viewModel.resetExportState()
                }
            }
            .alert(
                "エクスポートエラー",
                isPresented: Binding(
                    get: {
                        if case .failure = viewModel.exportState { return true }
                        return false
                    },
                    set: { if !$0 { viewModel.resetExportState() } }
                )
            ) {
                Button("OK") { viewModel.resetExportState() }
            } message: {
                if case .failure(let message) = viewModel.exportState {
                    Text(message)
                }
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var monthSection: some View {
        Section("月を選択") {
            if viewModel.availableMonths.isEmpty {
                Text("共有できるデータがありません")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.availableMonths) { month in
                    Button {
                        viewModel.selectedMonth = month
                    } label: {
                        HStack {
                            Text(month.displayString)
                                .foregroundStyle(.primary)
                            Spacer()
                            if viewModel.selectedMonth == month {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .accessibilityIdentifier("monthlyShare.monthRow.\(month.id)")
                }
            }
        }
    }

    @ViewBuilder
    private var formatSection: some View {
        Section("形式を選択") {
            ForEach(MonthlyShareFormat.allCases) { format in
                Button {
                    viewModel.selectedFormat = format
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(format.displayName)
                                .foregroundStyle(.primary)
                            Text(format.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if viewModel.selectedFormat == format {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .accessibilityIdentifier("monthlyShare.formatRow.\(format.rawValue)")
            }
        }
    }

    // MARK: - Bottom Bar

    @ViewBuilder
    private var bottomBar: some View {
        VStack(spacing: 8) {
            if case .exporting(let current, let total) = viewModel.exportState {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("\(current) / \(total) 件を処理中...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .accessibilityIdentifier("monthlyShare.progress")
            }

            Button {
                Task {
                    await viewModel.exportMonth()
                }
            } label: {
                Label("共有", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .disabled(
                viewModel.selectedMonth == nil
                    || {
                        if case .exporting = viewModel.exportState { return true }
                        return false
                    }()
            )
            .accessibilityIdentifier("monthlyShare.exportButton")
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .background(.regularMaterial)
    }
}
