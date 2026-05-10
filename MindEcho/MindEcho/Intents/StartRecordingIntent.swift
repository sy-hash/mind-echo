import AppIntents
import Foundation

struct StartRecordingIntent: AppIntent {
    static let title: LocalizedStringResource = "録音を開始"
    static let description = IntentDescription("MindEchoを開いて録音を開始します。")
    static var supportedModes: IntentModes { .foreground(.immediate) }

    func perform() async throws -> some IntentResult {
        RecordingLaunchRequestStore.requestStartRecording()
        return .result(dialog: "録音を開始します。")
    }
}

struct MindEchoShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartRecordingIntent(),
            phrases: [
                "\(.applicationName)で録音を開始",
                "\(.applicationName)で録音",
            ],
            shortTitle: "録音開始",
            systemImageName: "mic.circle.fill"
        )
    }
}
