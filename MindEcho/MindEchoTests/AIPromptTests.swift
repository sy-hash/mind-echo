import Testing
import Foundation
import MindEchoCore
@testable import MindEcho

@MainActor
struct AIPromptTests {
    private func makeRecording() -> Recording {
        Recording(
            sequenceNumber: 1,
            audioFileName: "20260222_120000.m4a",
            duration: 10.0,
            transcription: "テスト書き起こしテキスト"
        )
    }

    private func makeViewModel(
        processPromptResult: String = "AI適用結果テキスト"
    ) -> TranscriptionViewModel {
        let vm = TranscriptionViewModel()
        vm.processPrompt = { _, _ in processPromptResult }
        return vm
    }

    @Test func initialPromptState_isIdle() {
        let vm = TranscriptionViewModel()
        #expect(vm.promptState == .idle)
    }

    @Test func applyAIPrompt_success() async {
        let vm = makeViewModel()

        await vm.applyAIPrompt(transcriptionText: "テスト書き起こし", prompt: "要約して")

        #expect(vm.promptState == .success("AI適用結果テキスト"))
    }

    @Test func applyAIPrompt_emptyResult_failure() async {
        let vm = makeViewModel(processPromptResult: "")

        await vm.applyAIPrompt(transcriptionText: "テスト書き起こし", prompt: "要約して")

        #expect(vm.promptState == .failure("AI結果が空でした。"))
    }

    @Test func applyAIPrompt_error_failure() async {
        let vm = TranscriptionViewModel()
        vm.processPrompt = { _, _ in
            throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "テストエラー"])
        }

        await vm.applyAIPrompt(transcriptionText: "テスト書き起こし", prompt: "要約して")

        if case .failure(let message) = vm.promptState {
            #expect(message.contains("テストエラー"))
        } else {
            Issue.record("Expected failure state")
        }
    }

    @Test func applyAIPrompt_doesNotSaveToRecording() async {
        let vm = makeViewModel()
        let recording = makeRecording()
        let originalTranscription = recording.transcription
        let originalSummary = recording.summary

        await vm.applyAIPrompt(transcriptionText: recording.transcription ?? "", prompt: "要約して")

        #expect(vm.promptState == .success("AI適用結果テキスト"))
        #expect(recording.transcription == originalTranscription)
        #expect(recording.summary == originalSummary)
    }

    @Test func applyAIPrompt_canBeCalledMultipleTimes() async {
        let vm = TranscriptionViewModel()
        var callCount = 0
        vm.processPrompt = { _, _ in
            callCount += 1
            return "結果\(callCount)"
        }

        await vm.applyAIPrompt(transcriptionText: "テキスト", prompt: "プロンプト1")
        #expect(vm.promptState == .success("結果1"))

        await vm.applyAIPrompt(transcriptionText: "テキスト", prompt: "プロンプト2")
        #expect(vm.promptState == .success("結果2"))

        #expect(callCount == 2)
    }
}
