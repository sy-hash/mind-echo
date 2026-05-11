import AppIntents
import Foundation

enum RecordingLaunchTarget: String, AppEnum {
    case recording

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "MindEchoの起動先")
    static let caseDisplayRepresentations: [RecordingLaunchTarget: DisplayRepresentation] = [
        .recording: "録音"
    ]
}

struct StartRecordingIntent: OpenIntent {
    static let title: LocalizedStringResource = "録音を開始"
    static let description = IntentDescription("MindEchoを開いて録音を開始します。")
    static var supportedModes: IntentModes { .foreground(.immediate) }

    @Parameter(title: "起動先")
    var target: RecordingLaunchTarget

    init() {
        target = .recording
    }

    init(target: RecordingLaunchTarget) {
        self.target = target
    }

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
