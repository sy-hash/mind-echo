import Testing
import Foundation
import MindEchoCore
import Speech
@testable import MindEcho

@MainActor
struct TranscriptionViewModelTests {
    private func makeRecording() -> Recording {
        Recording(
            sequenceNumber: 1,
            audioFileName: "20260222_120000.m4a",
            duration: 10.0
        )
    }

    private func makeAuthorizedViewModel() -> TranscriptionViewModel {
        let vm = TranscriptionViewModel()
        vm.checkAuthorization = { .authorized }
        return vm
    }

    @Test func initialState_isIdle() {
        let vm = TranscriptionViewModel()
        #expect(vm.state == .idle)
    }

    @Test func startTranscription_showsLoadingThenSuccess() async throws {
        let vm = makeAuthorizedViewModel()
        vm.transcribe = { _, _ in
            try await Task.sleep(for: .milliseconds(100))
            return "テスト書き起こし結果"
        }

        let recording = makeRecording()

        let task = Task {
            await vm.startTranscription(recording: recording)
        }

        try await Task.sleep(for: .milliseconds(50))
        #expect(vm.state == .loading)

        await task.value
        #expect(vm.state == .success("テスト書き起こし結果"))
    }

    @Test func startTranscription_showsLoadingThenFailure() async throws {
        let vm = makeAuthorizedViewModel()
        vm.transcribe = { _, _ in
            try await Task.sleep(for: .milliseconds(100))
            throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "テストエラー"])
        }

        let recording = makeRecording()

        let task = Task {
            await vm.startTranscription(recording: recording)
        }

        try await Task.sleep(for: .milliseconds(50))
        #expect(vm.state == .loading)

        await task.value
        if case .failure(let message) = vm.state {
            #expect(message.contains("テストエラー"))
        } else {
            Issue.record("Expected failure state")
        }
    }

    @Test func startTranscription_emptyResult_showsFailure() async {
        let vm = makeAuthorizedViewModel()
        vm.transcribe = { _, _ in "" }

        let recording = makeRecording()
        await vm.startTranscription(recording: recording)
        #expect(vm.state == .failure("書き起こし結果が空でした。"))
    }
}
