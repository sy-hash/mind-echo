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

    @Test func fetchAllEntries_findsExistingEntry() throws {
        let (vm, _, _, _container) = try makeViewModel()
        vm.startRecording()
        vm.stopRecording()
        // Clear local reference
        vm.allEntries = []
        vm.fetchAllEntries()
        #expect(vm.todayEntry != nil)
        #expect(vm.todayEntry?.recordings.count == 1)
    }

    @Test func fetchAllEntries_returnsSortedByDateDescending() throws {
        let (vm, _, _, container) = try makeViewModel()
        let cal = Calendar.current
        let today = DateHelper.logicalDate()
        let yesterday = DateHelper.logicalDate(for: cal.date(byAdding: .day, value: -1, to: Date())!)
        let entry1 = JournalEntry(date: yesterday)
        let entry2 = JournalEntry(date: today)
        container.mainContext.insert(entry1)
        container.mainContext.insert(entry2)
        vm.fetchAllEntries()
        #expect(vm.allEntries.count == 2)
        #expect(vm.allEntries[0].date >= vm.allEntries[1].date)
    }

    @Test func deleteEntry_removesFromList() throws {
        let (vm, _, _, container) = try makeViewModel()
        let entry = JournalEntry(date: DateHelper.logicalDate())
        container.mainContext.insert(entry)
        vm.fetchAllEntries()
        #expect(vm.allEntries.count == 1)
        vm.deleteEntry(entry)
        #expect(vm.allEntries.isEmpty)
    }

    @Test func deleteRecording_removesFromEntry() throws {
        let (vm, _, _, container) = try makeViewModel()
        let entry = JournalEntry(date: DateHelper.logicalDate())
        let recording = Recording(sequenceNumber: 1, audioFileName: "test.m4a", duration: 30)
        entry.recordings.append(recording)
        container.mainContext.insert(entry)
        vm.fetchAllEntries()
        #expect(vm.todayEntry?.recordings.count == 1)
        vm.deleteRecording(recording, from: entry)
        // Entry should be removed since it has no more recordings
        #expect(vm.allEntries.isEmpty)
    }

    @Test func deleteRecording_keepsEntryWithRemainingRecordings() throws {
        let (vm, _, _, container) = try makeViewModel()
        let entry = JournalEntry(date: DateHelper.logicalDate())
        let recording1 = Recording(sequenceNumber: 1, audioFileName: "test1.m4a", duration: 30)
        let recording2 = Recording(sequenceNumber: 2, audioFileName: "test2.m4a", duration: 45)
        entry.recordings.append(recording1)
        entry.recordings.append(recording2)
        container.mainContext.insert(entry)
        vm.fetchAllEntries()
        #expect(vm.todayEntry?.recordings.count == 2)
        vm.deleteRecording(recording1, from: entry)
        #expect(vm.allEntries.count == 1)
        #expect(vm.todayEntry?.recordings.count == 1)
    }

    @Test func sectionTitle_today() throws {
        let (vm, _, _, container) = try makeViewModel()
        let entry = JournalEntry(date: DateHelper.today())
        container.mainContext.insert(entry)
        vm.fetchAllEntries()
        #expect(vm.sectionTitle(for: entry) == "今日")
    }

    @Test func sectionTitle_yesterday() throws {
        let (vm, _, _, container) = try makeViewModel()
        let cal = Calendar.current
        let yesterdayDate = DateHelper.logicalDate(for: cal.date(byAdding: .day, value: -1, to: Date())!)
        let entry = JournalEntry(date: yesterdayDate)
        container.mainContext.insert(entry)
        vm.fetchAllEntries()
        #expect(vm.sectionTitle(for: entry) == "昨日")
    }

    @Test func sectionTitle_olderDate_showsFormattedDate() throws {
        let (vm, _, _, container) = try makeViewModel()
        let cal = Calendar.current
        let olderDate = DateHelper.logicalDate(for: cal.date(byAdding: .day, value: -5, to: Date())!)
        let entry = JournalEntry(date: olderDate)
        container.mainContext.insert(entry)
        vm.fetchAllEntries()
        let title = vm.sectionTitle(for: entry)
        #expect(title != "今日")
        #expect(title != "昨日")
        #expect(title == DateHelper.displayString(for: olderDate))
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
}
