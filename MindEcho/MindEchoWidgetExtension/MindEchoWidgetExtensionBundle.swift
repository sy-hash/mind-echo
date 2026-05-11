//
//  MindEchoWidgetExtensionBundle.swift
//  MindEchoWidgetExtension
//
//  Created by sy-hash on 2026/05/11.
//

import WidgetKit
import SwiftUI

@main
struct MindEchoWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        MindEchoWidgetExtension()
        MindEchoWidgetExtensionControl()
    }
}
