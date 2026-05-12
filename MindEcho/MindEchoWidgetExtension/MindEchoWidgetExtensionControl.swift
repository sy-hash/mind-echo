//
//  MindEchoWidgetExtensionControl.swift
//  MindEchoWidgetExtension
//
//  Created by sy-hash on 2026/05/11.
//

import AppIntents
import SwiftUI
import WidgetKit

struct MindEchoWidgetExtensionControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: "com.syhash.MindEcho.quickRecord"
        ) {
            ControlWidgetButton(
                action: QuickRecordIntent(target: .quickRecord)
            ) {
                Label("クイック録音", systemImage: "mic.fill")
            }
        }
        .displayName("クイック録音")
        .description("MindEchoを開いて録音を開始します。")
    }
}
