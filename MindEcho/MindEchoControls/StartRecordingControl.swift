import AppIntents
import SwiftUI
import WidgetKit

struct StartRecordingControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.syhash.MindEcho.startRecording") {
            ControlWidgetButton(action: StartRecordingIntent()) {
                Label("録音開始", systemImage: "mic.circle.fill")
            }
            .tint(.red)
        }
        .displayName("録音開始")
        .description("MindEchoを開いて録音を開始します。")
    }
}
