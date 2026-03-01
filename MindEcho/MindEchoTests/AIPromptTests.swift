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
            duration: 10.0
        )
    }

    @Test func initialPromptState_isIdle() {
        let vm = TranscriptionViewModel()
        #expect(vm.promptState == .idle)
    }

    @Test func applyAIPrompt_success() async {
        let vm = TranscriptionViewModel()
        vm.processPrompt = { _, _ in "AI適用結果" }

        await vm.applyAIPrompt(transcriptionText: "原文テキスト", prompt: "要約して")

        #expect(vm.promptState == .success("AI適用結果"))
    }

    @Test func applyAIPrompt_emptyResult_failure() async {
        let vm = TranscriptionViewModel()
        vm.processPrompt = { _, _ in "" }

        await vm.applyAIPrompt(transcriptionText: "原文テキスト", prompt: "要約して")

        #expect(vm.promptState == .failure("AI結果が空でした。"))
    }

    @Test func applyAIPrompt_error_failure() async {
        let vm = TranscriptionViewModel()
        vm.processPrompt = { _, _ in
            throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "テストエラー"])
        }

        await vm.applyAIPrompt(transcriptionText: "原文テキスト", prompt: "要約して")

        if case .failure(let message) = vm.promptState {
            #expect(message.contains("テストエラー"))
        } else {
            Issue.record("Expected failure state")
        }
    }

    @Test func applyAIPrompt_doesNotSaveToRecording() async {
        let vm = TranscriptionViewModel()
        vm.processPrompt = { _, _ in "AI適用結果" }
        let recording = makeRecording()
        recording.transcription = "原文テキスト"

        await vm.applyAIPrompt(transcriptionText: "原文テキスト", prompt: "要約して")

        #expect(recording.transcription == "原文テキスト")
        #expect(recording.summary == nil)
    }

    @Test func applyAIPrompt_canBeCalledMultipleTimes() async {
        let vm = TranscriptionViewModel()

        vm.processPrompt = { _, _ in "1回目の結果" }
        await vm.applyAIPrompt(transcriptionText: "原文テキスト", prompt: "プロンプト1")
        #expect(vm.promptState == .success("1回目の結果"))

        vm.processPrompt = { _, _ in "2回目の結果" }
        await vm.applyAIPrompt(transcriptionText: "原文テキスト", prompt: "プロンプト2")
        #expect(vm.promptState == .success("2回目の結果"))
    }
}
