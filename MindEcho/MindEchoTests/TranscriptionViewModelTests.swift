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
        vm.transcribe = { _, _, _, _, _ in
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

    @Test func startTranscription_savesTranscriptionToRecording() async {
        let vm = makeAuthorizedViewModel()
        vm.transcribe = { _, _, _, _, _ in "保存されるテキスト" }

        let recording = makeRecording()
        #expect(recording.transcription == nil)

        await vm.startTranscription(recording: recording)

        #expect(recording.transcription == "保存されるテキスト")
        #expect(vm.state == .success("保存されるテキスト"))
    }

    @Test func startTranscription_existingTranscription_showsImmediately() async {
        let vm = makeAuthorizedViewModel()
        var transcribeCalled = false
        vm.transcribe = { _, _, _, _, _ in
            transcribeCalled = true
            return "新しいテキスト"
        }

        let recording = makeRecording()
        recording.transcription = "既存の書き起こし"

        await vm.startTranscription(recording: recording)

        #expect(vm.state == .success("既存の書き起こし"))
        #expect(!transcribeCalled)
    }

    @Test func startTranscription_showsLoadingThenFailure() async throws {
        let vm = makeAuthorizedViewModel()
        vm.transcribe = { _, _, _, _, _ in
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
        vm.transcribe = { _, _, _, _, _ in "" }

        let recording = makeRecording()
        await vm.startTranscription(recording: recording)
        #expect(vm.state == .failure("書き起こし結果が空でした。"))
        #expect(recording.transcription == nil)
    }

    @Test func startTranscription_failure_doesNotSaveTranscription() async {
        let vm = makeAuthorizedViewModel()
        vm.transcribe = { _, _, _, _, _ in
            throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "エラー"])
        }

        let recording = makeRecording()
        await vm.startTranscription(recording: recording)
        #expect(recording.transcription == nil)
    }

    @Test func retryTranscription_clearsAndRetranscribes() async {
        let vm = makeAuthorizedViewModel()
        var callCount = 0
        vm.transcribe = { _, _, _, _, _ in
            callCount += 1
            return "書き起こし結果\(callCount)"
        }
        vm.isSummarizationAvailable = { false }

        let recording = makeRecording()
        await vm.startTranscription(recording: recording)

        #expect(vm.state == .success("書き起こし結果1"))
        #expect(recording.transcription == "書き起こし結果1")

        // Set a summary to verify it gets cleared
        recording.summary = "テスト要約"

        await vm.retryTranscription(recording: recording)

        #expect(vm.state == .success("書き起こし結果2"))
        #expect(recording.transcription == "書き起こし結果2")
        #expect(recording.summary == nil)
        #expect(callCount == 2)
    }

    @Test func startTranscription_passesVocabularyToTranscribe() async {
        let vm = makeAuthorizedViewModel()
        var receivedWords: [String] = []
        vm.transcribe = { _, _, words, _, _ in
            receivedWords = words
            return "テスト"
        }
        vm.vocabularyWords = ["固有名詞", "専門用語"]

        let recording = makeRecording()
        await vm.startTranscription(recording: recording)

        #expect(receivedWords == ["固有名詞", "専門用語"])
    }
}
