import AVFoundation
import MindEchoAudio
import MindEchoCore
import SwiftData
import SwiftUI

@main
struct MindEchoApp: App {
    private let modelContainer: ModelContainer
    private let audioRecorder: any AudioRecording
    private let audioPlayer: any AudioPlaying

    init() {
        let args = ProcessInfo.processInfo.arguments
        let isUITesting = args.contains("--uitesting")
        let useMockRecorder = args.contains("--mock-recorder")
        let useMockPlayer = args.contains("--mock-player")

        let schema = Schema([
            JournalEntry.self,
            Recording.self,
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

        if useMockPlayer {
            audioPlayer = MockAudioPlayerService()
        } else {
            audioPlayer = AudioPlayerService()
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
                    HistoryListView(
                        modelContext: modelContainer.mainContext,
                        audioPlayer: audioPlayer
                    )
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
            let fileName = "sample_\(dayOffset).m4a"
            let duration = TimeInterval(60 * dayOffset)
            createSilentAudioFile(named: fileName, duration: 10)
            let recording = Recording(
                sequenceNumber: 1,
                audioFileName: fileName,
                duration: duration
            )
            let transcriptions = [
                "朝から天気が良かったので、近所の公園を散歩した。桜がもう少しで咲きそうだった。",
                "今日はカレーを作った。スパイスを多めに入れたら結構辛くなったけど美味しかった。",
                "仕事帰りに本屋に寄って、前から気になっていた小説を買った。電車の中で少し読み始めた。",
                "久しぶりに友達とカフェでランチした。お互いの近況を話して楽しい時間だった。",
                "夜、録りためていたドラマを一気に見た。最終回が予想外の展開で驚いた。",
            ]
            recording.transcription = transcriptions[dayOffset - 1]
            entry.recordings.append(recording)
            context.insert(entry)
        }
    }

    @MainActor
    private static func seedTodayWithRecordings(context: ModelContext) {
        let today = DateHelper.today()
        let entry = JournalEntry(date: today)
        for i in 1...3 {
            let fileName = "today_\(i).m4a"
            let duration = TimeInterval(30 * i)
            createSilentAudioFile(named: fileName, duration: 10)
            let recording = Recording(
                sequenceNumber: i,
                audioFileName: fileName,
                duration: duration
            )
            entry.recordings.append(recording)
        }
        context.insert(entry)
    }

    /// Creates a silent audio file in the recordings directory using AVAudioFile.
    private static func createSilentAudioFile(named fileName: String, duration: TimeInterval) {
        let dir = FilePathManager.recordingsDirectory
        try? FilePathManager.ensureDirectoryExists(dir)
        let url = dir.appendingPathComponent(fileName)

        let sampleRate: Double = 44100
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.low.rawValue,
        ]
        do {
            let file = try AVAudioFile(forWriting: url, settings: settings, commonFormat: .pcmFormatFloat32, interleaved: false)
            try file.write(from: buffer)
        } catch {
            // Fallback: create as CAF/PCM
            guard let pcmFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
            do {
                let file = try AVAudioFile(forWriting: url, settings: pcmFormat.settings)
                try file.write(from: buffer)
            } catch {}
        }
    }

}
