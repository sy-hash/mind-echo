import Testing
import Foundation
import SwiftData
@testable import MindEcho

@MainActor
struct HomeViewModelTests {
    private func makeViewModel() throws -> (HomeViewModel, MockAudioRecorderService, MockAudioPlayerService, ModelContainer) {
        let schema = Schema([JournalEntry.self, Recording.self, TextEntry.self])
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

    @Test func saveText_createsTextEntry() throws {
        let (vm, _, _, _container) = try makeViewModel()
        vm.saveText("Hello World")
        #expect(vm.todayEntry != nil)
        #expect(vm.todayEntry?.textEntries.count == 1)
        #expect(vm.todayEntry?.sortedTextEntries.first?.content == "Hello World")
    }

    @Test func saveText_updatesExistingTextEntry() throws {
        let (vm, _, _, _container) = try makeViewModel()
        vm.saveText("First")
        vm.saveText("Updated")
        #expect(vm.todayEntry?.textEntries.count == 1)
        #expect(vm.todayEntry?.sortedTextEntries.first?.content == "Updated")
    }

    @Test func fetchTodayEntry_findsExistingEntry() throws {
        let (vm, _, _, _container) = try makeViewModel()
        vm.saveText("Test text")
        // Clear local reference
        vm.todayEntry = nil
        vm.fetchTodayEntry()
        #expect(vm.todayEntry != nil)
        #expect(vm.todayEntry?.sortedTextEntries.first?.content == "Test text")
    }
}
