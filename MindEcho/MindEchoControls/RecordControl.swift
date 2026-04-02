import AppIntents
import SwiftUI
import WidgetKit

struct RecordControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.syhash.MindEcho.recordControl") {
            ControlWidgetButton(action: StartRecordingIntent()) {
                Label("録音開始", systemImage: "mic.fill")
            }
        }
        .displayName("録音開始")
        .description("MindEchoを開いてすぐに録音を始めます。")
    }
}

struct StartRecordingIntent: AppIntent {
    static let title: LocalizedStringResource = "録音開始"
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult & OpensIntent {
        .result(opensIntent: OpenURLIntent(URL(string: "mindecho://record")!))
    }
}
