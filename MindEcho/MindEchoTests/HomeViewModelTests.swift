import Testing
import Foundation
import MindEchoAudio
import MindEchoCore
import SwiftData
@testable import MindEcho

@MainActor
struct HomeViewModelTests {
    private func makeViewModel() throws -> (HomeViewModel, MockAudioRecorderService, MockAudioPlayerService, ModelContainer) {
        let schema = Schema([JournalEntry.self, Recording.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext
        let recorder = MockAudioRecorderService()
        let player = MockAudioPlayerService()
        let vm = HomeViewModel(modelContext: context, audioRecorder: recorder, audioPlayer: player)
        return (vm, recorder, player, container)
    }

    @Test func initialState_notRecording() throws {
        let (vm, _, _, _container) = try makeViewModel()
        #expect(vm.isRecording == false)
        #expect(vm.isRecordingPaused == false)
        #expect(vm.todayEntry == nil)
    }

    @Test func startRecording_setsRecordingState() throws {
        let (vm, recorder, _, _container) = try makeViewModel()
        vm.startRecording()
        #expect(recorder.isRecording == true)
        #expect(vm.isRecording == true)
    }

    @Test func pauseRecording_setsPausedState() throws {
        let (vm, recorder, _, _container) = try makeViewModel()
        vm.startRecording()
        vm.pauseRecording()
        #expect(recorder.isPaused == true)
        #expect(vm.isRecordingPaused == true)
    }

    @Test func resumeRecording_clearsPausedState() throws {
        let (vm, recorder, _, _container) = try makeViewModel()
        vm.startRecording()
        vm.pauseRecording()
        vm.resumeRecording()
        #expect(recorder.isPaused == false)
        #expect(vm.isRecordingPaused == false)
        #expect(vm.isRecording == true)
    }

    @Test func stopRecording_createsRecordingEntry() throws {
        let (vm, _, _, _container) = try makeViewModel()
        vm.startRecording()
        vm.stopRecording()
        #expect(vm.isRecording == false)
        #expect(vm.todayEntry != nil)
        #expect(vm.todayEntry?.recordings.count == 1)
        #expect(vm.todayEntry?.recordings.first?.sequenceNumber == 1)
    }

    @Test func multipleRecordings_incrementSequenceNumber() throws {
        let (vm, _, _, _container) = try makeViewModel()
        vm.startRecording()
        vm.stopRecording()
        vm.startRecording()
        vm.stopRecording()
        #expect(vm.todayEntry?.recordings.count == 2)
        let seqs = vm.todayEntry?.sortedRecordings.map(\.sequenceNumber) ?? []
        #expect(seqs == [1, 2])
    }

    @Test func fetchTodayEntry_findsExistingEntry() throws {
        let (vm, _, _, _container) = try makeViewModel()
        vm.startRecording()
        vm.stopRecording()
        // Clear local reference
        vm.todayEntry = nil
        vm.fetchTodayEntry()
        #expect(vm.todayEntry != nil)
        #expect(vm.todayEntry?.recordings.count == 1)
    }

    @Test func startTranscription_savesTranscriptionToRecording() async throws {
        let (vm, _, _, _container) = try makeViewModel()
        vm.transcribe = { _, _ in "書き起こしテスト結果" }
        vm.startRecording()
        vm.stopRecording()

        await vm.startTranscription()

        let recording = vm.todayEntry?.sortedRecordings.first
        #expect(recording?.transcription == "書き起こしテスト結果")
    }

    @Test func startTranscription_emptyResult_doesNotSave() async throws {
        let (vm, _, _, _container) = try makeViewModel()
        vm.transcribe = { _, _ in "" }
        vm.startRecording()
        vm.stopRecording()

        await vm.startTranscription()

        let recording = vm.todayEntry?.sortedRecordings.first
        #expect(recording?.transcription == nil)
    }

    @Test func fetchAllEntries_separatesTodayAndPast() throws {
        let schema = Schema([JournalEntry.self, Recording.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext
        let recorder = MockAudioRecorderService()
        let player = MockAudioPlayerService()
        let vm = HomeViewModel(modelContext: context, audioRecorder: recorder, audioPlayer: player)

        // Create today's entry
        let todayEntry = JournalEntry(date: DateHelper.logicalDate())
        let todayRecording = Recording(sequenceNumber: 1, audioFileName: "today.m4a", duration: 30)
        todayEntry.recordings.append(todayRecording)
        context.insert(todayEntry)

        // Create a past entry
        let pastDate = Calendar.current.date(byAdding: .day, value: -1, to: DateHelper.logicalDate())!
        let pastEntry = JournalEntry(date: DateHelper.logicalDate(for: pastDate))
        let pastRecording = Recording(sequenceNumber: 1, audioFileName: "past.m4a", duration: 60)
        pastEntry.recordings.append(pastRecording)
        context.insert(pastEntry)

        vm.fetchAllEntries()

        #expect(vm.todayEntry != nil)
        #expect(vm.pastRows.count >= 1)
    }

    @Test func fetchAllEntries_gappedDates_includesMissingDatesWithNilEntry() throws {
        let schema = Schema([JournalEntry.self, Recording.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext
        let recorder = MockAudioRecorderService()
        let player = MockAudioPlayerService()
        let vm = HomeViewModel(modelContext: context, audioRecorder: recorder, audioPlayer: player)

        let cal = Calendar.current
        let today = DateHelper.logicalDate()
        // 1・3・5日前にエントリを作成（2・4日前は歯抜け）
        let daysWithEntries = [-1, -3, -5]
        var entryDates: [Date] = []
        for offset in daysWithEntries {
            let date = cal.date(byAdding: .day, value: offset, to: today)!
            let logicalDate = DateHelper.logicalDate(for: date)
            let entry = JournalEntry(date: logicalDate)
            let recording = Recording(sequenceNumber: 1, audioFileName: "rec\(offset).m4a", duration: 10)
            entry.recordings.append(recording)
            context.insert(entry)
            entryDates.append(logicalDate)
        }

        vm.fetchAllEntries()

        // 1〜5日前の5行が生成されること
        #expect(vm.pastRows.count == 5)

        // 1・3・5日前は entry が非 nil
        for offset in daysWithEntries {
            let date = DateHelper.logicalDate(for: cal.date(byAdding: .day, value: offset, to: today)!)
            let row = vm.pastRows.first { $0.date == date }
            #expect(row != nil, "offset \(offset) の行が存在すること")
            #expect(row?.entry != nil, "offset \(offset) の行は entry を持つこと")
        }

        // 2・4日前は entry が nil（歯抜け日付）
        for offset in [-2, -4] {
            let date = DateHelper.logicalDate(for: cal.date(byAdding: .day, value: offset, to: today)!)
            let row = vm.pastRows.first { $0.date == date }
            #expect(row != nil, "offset \(offset) の行が存在すること")
            #expect(row?.entry == nil, "offset \(offset) の行は entry を持たないこと")
        }
    }

    @Test func startTranscription_triggersSummarization() async throws {
        let (vm, _, _, _container) = try makeViewModel()
        vm.transcribe = { _, _ in "書き起こしテスト結果" }
        vm.summarize = { _ in "要約テスト結果" }
        vm.isSummarizationAvailable = { true }
        vm.startRecording()
        vm.stopRecording()

        await vm.startTranscription()

        let recording = vm.todayEntry?.sortedRecordings.first
        #expect(recording?.transcription == "書き起こしテスト結果")
        #expect(recording?.summary == "要約テスト結果")
        #expect(vm.summaryState == .success("要約テスト結果"))
    }

    @Test func startTranscription_summarizationUnavailable() async throws {
        let (vm, _, _, _container) = try makeViewModel()
        vm.transcribe = { _, _ in "書き起こしテスト結果" }
        vm.isSummarizationAvailable = { false }
        vm.startRecording()
        vm.stopRecording()

        await vm.startTranscription()

        let recording = vm.todayEntry?.sortedRecordings.first
        #expect(recording?.transcription == "書き起こしテスト結果")
        #expect(recording?.summary == nil)
        #expect(vm.summaryState == .unavailable)
    }

    @Test func startTranscription_survivesDismiss() async throws {
        let (vm, _, _, _container) = try makeViewModel()
        vm.transcribe = { _, _ in
            try await Task.sleep(for: .milliseconds(50))
            return "書き起こしテスト結果"
        }
        vm.summarize = { _ in "要約テスト結果" }
        vm.isSummarizationAvailable = { true }
        vm.startRecording()
        vm.stopRecording()

        let recording = vm.todayEntry?.sortedRecordings.first

        let task = Task { await vm.startTranscription() }
        // Simulate modal dismiss during transcription
        vm.resetTranscriptionState()
        await task.value

        // Recording should still have transcription and summary saved
        #expect(recording?.transcription == "書き起こしテスト結果")
        #expect(recording?.summary == "要約テスト結果")
    }

    @Test func startTranscription_emptyResult_doesNotSummarize() async throws {
        let (vm, _, _, _container) = try makeViewModel()
        var summarizeCalled = false
        vm.transcribe = { _, _ in "" }
        vm.summarize = { _ in
            summarizeCalled = true
            return "should not be called"
        }
        vm.isSummarizationAvailable = { true }
        vm.startRecording()
        vm.stopRecording()

        await vm.startTranscription()

        #expect(summarizeCalled == false)
        #expect(vm.summaryState == .idle)
    }

    @Test func resetTranscriptionState_resetsSummaryState() async throws {
        let (vm, _, _, _container) = try makeViewModel()
        vm.transcribe = { _, _ in "テスト" }
        vm.summarize = { _ in "要約" }
        vm.isSummarizationAvailable = { true }
        vm.startRecording()
        vm.stopRecording()

        await vm.startTranscription()
        #expect(vm.summaryState == .success("要約"))

        vm.resetTranscriptionState()
        #expect(vm.summaryState == .idle)
    }

    @Test func deleteRecording_removesFromEntry() throws {
        let (vm, _, _, _container) = try makeViewModel()
        vm.startRecording()
        vm.stopRecording()
        #expect(vm.todayEntry?.recordings.count == 1)

        let recording = vm.todayEntry!.recordings.first!
        vm.deleteRecording(recording, from: vm.todayEntry!)
        #expect(vm.todayEntry == nil) // Entry deleted since it had no more recordings
    }
}
