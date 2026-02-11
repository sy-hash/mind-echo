import SwiftUI
import SwiftData

@main
struct MindEchoApp: App {
    private let modelContainer: ModelContainer
    private let audioRecorder: any AudioRecording

    init() {
        let args = ProcessInfo.processInfo.arguments
        let isUITesting = args.contains("--uitesting")
        let useMockRecorder = args.contains("--mock-recorder")

        let schema = Schema([
            JournalEntry.self,
            Recording.self,
            TextEntry.self,
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isUITesting
        )
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }

        if useMockRecorder {
            audioRecorder = MockAudioRecorderService()
        } else {
            audioRecorder = AudioRecorderService()
        }

        // Seed data for UI testing
        if isUITesting {
            let context = modelContainer.mainContext
            if args.contains("--seed-history") {
                Self.seedHistory(context: context)
            }
            if args.contains("--seed-today-with-recordings") {
                Self.seedTodayWithRecordings(context: context)
            }
            if args.contains("--seed-today-with-text") {
                Self.seedTodayWithText(context: context)
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                Tab("今日", systemImage: "mic.circle.fill") {
                    HomeView(
                        modelContext: modelContainer.mainContext,
                        audioRecorder: audioRecorder
                    )
                }
                .accessibilityIdentifier("tab.today")

                Tab("履歴", systemImage: "calendar") {
                    HistoryListView(modelContext: modelContainer.mainContext)
                }
                .accessibilityIdentifier("tab.history")
            }
        }
        .modelContainer(modelContainer)
    }

    // MARK: - Seed Data

    @MainActor
    private static func seedHistory(context: ModelContext) {
        let calendar = Calendar.current
        for dayOffset in 1...5 {
            let referenceDate = calendar.date(
                byAdding: .day,
                value: -dayOffset,
                to: Date()
            )!
            let logicalDate = DateHelper.logicalDate(for: referenceDate)
            let entry = JournalEntry(date: logicalDate)
            let textEntry = TextEntry(
                sequenceNumber: 1,
                content: "サンプルテキスト \(dayOffset)日前"
            )
            entry.textEntries.append(textEntry)
            let recording = Recording(
                sequenceNumber: 1,
                audioFileName: "sample_\(dayOffset).m4a",
                duration: TimeInterval(60 * dayOffset)
            )
            entry.recordings.append(recording)
            context.insert(entry)
        }
    }

    @MainActor
    private static func seedTodayWithRecordings(context: ModelContext) {
        let today = DateHelper.today()
        let entry = JournalEntry(date: today)
        for i in 1...3 {
            let recording = Recording(
                sequenceNumber: i,
                audioFileName: "today_\(i).m4a",
                duration: TimeInterval(30 * i)
            )
            entry.recordings.append(recording)
        }
        context.insert(entry)
    }

    @MainActor
    private static func seedTodayWithText(context: ModelContext) {
        let today = DateHelper.today()
        let entry = JournalEntry(date: today)
        let textEntry = TextEntry(
            sequenceNumber: 1,
            content: "今日のテストテキスト"
        )
        entry.textEntries.append(textEntry)
        context.insert(entry)
    }
}
