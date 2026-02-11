import SwiftUI
import SwiftData

struct HistoryListView: View {
    @State private var viewModel: HistoryViewModel
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        _viewModel = State(initialValue: HistoryViewModel(modelContext: modelContext))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.entries.isEmpty {
                    ContentUnavailableView("履歴がありません", systemImage: "calendar")
                } else {
                    List {
                        ForEach(viewModel.entries) { entry in
                            NavigationLink(value: entry) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(DateHelper.displayString(for: entry.date))
                                        .font(.headline)
                                        .accessibilityIdentifier("history.entryDate.\(dateTag(entry.date))")

                                    if let text = entry.sortedTextEntries.first?.content, !text.isEmpty {
                                        Text(text)
                                            .lineLimit(2)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .accessibilityIdentifier("history.entryPreview.\(dateTag(entry.date))")
                                    }

                                    if !entry.recordings.isEmpty {
                                        Text("\u{1F3A4} \(entry.recordings.count)件 / \(formatTotalDuration(entry.totalDuration))")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .accessibilityIdentifier("history.entryRecordingInfo.\(dateTag(entry.date))")
                                    }
                                }
                            }
                            .accessibilityIdentifier("history.entryRow.\(dateTag(entry.date))")
                        }
                    }
                    .accessibilityIdentifier("history.entryList")
                }
            }
            .navigationTitle("履歴")
            .navigationDestination(for: JournalEntry.self) { entry in
                EntryDetailView(entry: entry, modelContext: modelContext)
            }
            .onAppear {
                viewModel.fetchEntries()
            }
        }
    }

    private func dateTag(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: date)
    }

    private func formatTotalDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return "\(minutes)m\(String(format: "%02d", seconds))s"
    }
}
