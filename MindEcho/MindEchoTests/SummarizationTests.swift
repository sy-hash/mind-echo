import Testing
import Foundation
import Speech
import MindEchoCore
@testable import MindEcho

@MainActor
struct SummarizationTests {
    private func makeRecording(transcription: String? = nil, summary: String? = nil) -> Recording {
        let recording = Recording(
            sequenceNumber: 1,
            audioFileName: "20260222_120000.m4a",
            duration: 10.0,
            transcription: transcription,
            summary: summary
        )
        return recording
    }

    private func makeViewModel(
        summarizeResult: String = "テスト要約結果",
        available: Bool = true
    ) -> TranscriptionViewModel {
        let vm = TranscriptionViewModel()
        vm.checkAuthorization = { .authorized }
        vm.transcribe = { _, _, _, _, _ in "テスト書き起こし結果" }
        vm.summarize = { _, _ in summarizeResult }
        vm.isSummarizationAvailable = { available }
        return vm
    }

    @Test func initialSummaryState_isIdle() {
        let vm = TranscriptionViewModel()
        #expect(vm.summaryState == .idle)
    }

    @Test func startSummarization_savesSummaryToRecording() async {
        let vm = makeViewModel()
        let recording = makeRecording(transcription: "既存テキスト")

        await vm.startTranscription(recording: recording)

        #expect(recording.summary == "テスト要約結果")
        #expect(vm.summaryState == .success("テスト要約結果"))
    }

    @Test func startSummarization_existingSummary_showsImmediately() async {
        let vm = makeViewModel()
        var summarizeCalled = false
        vm.summarize = { _, _ in
            summarizeCalled = true
            return "新しい要約"
        }

        let recording = makeRecording(transcription: "テキスト", summary: "既存の要約")

        await vm.startTranscription(recording: recording)

        #expect(vm.summaryState == .success("既存の要約"))
        #expect(!summarizeCalled)
    }

    @Test func startSummarization_unavailableDevice_showsUnavailable() async {
        let vm = makeViewModel(available: false)
        let recording = makeRecording(transcription: "テキスト")

        await vm.startTranscription(recording: recording)

        #expect(vm.summaryState == .unavailable)
        #expect(recording.summary == nil)
    }

    @Test func startSummarization_emptyResult_showsFailure() async {
        let vm = makeViewModel(summarizeResult: "")
        let recording = makeRecording(transcription: "テキスト")

        await vm.startTranscription(recording: recording)

        #expect(vm.summaryState == .failure("要約結果が空でした。"))
        #expect(recording.summary == nil)
    }

    @Test func startSummarization_error_showsFailure() async {
        let vm = makeViewModel()
        vm.summarize = { _, _ in
            throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "テストエラー"])
        }
        let recording = makeRecording(transcription: "テキスト")

        await vm.startTranscription(recording: recording)

        if case .failure(let message) = vm.summaryState {
            #expect(message.contains("テストエラー"))
        } else {
            Issue.record("Expected failure state")
        }
        #expect(recording.summary == nil)
    }

    @Test func startSummarization_failure_doesNotSaveSummary() async {
        let vm = makeViewModel()
        vm.summarize = { _, _ in
            throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "エラー"])
        }
        let recording = makeRecording(transcription: "テキスト")

        await vm.startTranscription(recording: recording)

        #expect(recording.summary == nil)
    }

    @Test func transcriptionSuccess_triggersSummarization() async {
        let vm = makeViewModel()
        let recording = makeRecording()

        await vm.startTranscription(recording: recording)

        #expect(vm.state == .success("テスト書き起こし結果"))
        #expect(vm.summaryState == .success("テスト要約結果"))
        #expect(recording.transcription == "テスト書き起こし結果")
        #expect(recording.summary == "テスト要約結果")
    }

    @Test func transcriptionFailure_doesNotTriggerSummarization() async {
        let vm = makeViewModel()
        vm.transcribe = { _, _, _, _, _ in
            throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "エラー"])
        }
        let recording = makeRecording()

        await vm.startTranscription(recording: recording)

        #expect(vm.summaryState == .idle)
    }
}
