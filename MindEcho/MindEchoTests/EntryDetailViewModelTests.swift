import Testing
import Foundation
import MindEchoAudio
import MindEchoCore
import SwiftData
@testable import MindEcho

@MainActor
struct EntryDetailViewModelTests {
    private func makeViewModel() throws -> (EntryDetailViewModel, JournalEntry, MockAudioPlayerService, ModelContext, ModelContainer) {
        let schema = Schema([JournalEntry.self, Recording.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let entry = JournalEntry(date: DateHelper.logicalDate())
        context.insert(entry)

        let player = MockAudioPlayerService()
        let vm = EntryDetailViewModel(
            entry: entry,
            modelContext: context,
            audioPlayer: player
        )
        return (vm, entry, player, context, container)
    }

    @Test func initialState() throws {
        let (vm, _, _, _, _container) = try makeViewModel()
        #expect(vm.isPlaying == false)
        #expect(vm.playingRecordingId == nil)
    }

    @Test func deleteRecording_removesFromEntry() throws {
        let (vm, entry, _, _, _container) = try makeViewModel()
        let recording = Recording(sequenceNumber: 1, audioFileName: "test.m4a", duration: 30)
        entry.recordings.append(recording)
        #expect(entry.recordings.count == 1)
        vm.deleteRecording(recording)
        #expect(entry.recordings.count == 0)
    }

    @Test func stopPlayback_resetsState() throws {
        let (vm, _, _, _, _container) = try makeViewModel()
        vm.stopPlayback()
        #expect(vm.isPlaying == false)
        #expect(vm.playingRecordingId == nil)
        #expect(vm.playbackProgress == 0)
    }
}
