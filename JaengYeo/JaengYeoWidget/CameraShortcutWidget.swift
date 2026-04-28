//
//  CameraShortcutWidget.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/28/26.
//

import WidgetKit
import SwiftUI

struct CameraShortcutEntry: TimelineEntry {
    let date: Date
}

struct CameraShortcutProvider: TimelineProvider {
    func placeholder(in context: Context) -> CameraShortcutEntry {
        CameraShortcutEntry(date: Date())
    }
    func getSnapshot(in context: Context, completion: @escaping (CameraShortcutEntry) -> Void) {
        completion(CameraShortcutEntry(date: Date()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<CameraShortcutEntry>) -> Void) {
        let entry = CameraShortcutEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct CameraShortcutWidget: Widget {
    let kind: String = "CameraShortcutWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CameraShortcutProvider()) { entry in
            CameraShortcutWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("카메라 바로가기")
        .description("탭으로 등록 화면 진입")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct CameraShortcutWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: CameraShortcutEntry
    var body: some View {
        switch family {
        case .systemSmall:
            CameraShortcutSmallView()
        case .systemMedium:
            CameraShortcutMediumView()
        default:
            CameraShortcutSmallView()
        }
    }
}

struct CameraShortcutSmallView: View {
    var body: some View {
        Link(destination: cameraURL(mode: .barcode)) {
            VStack(spacing: 8) {
                Image("barcodeIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                Text("바코드 스캔")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct CameraShortcutMediumView: View {
    var body: some View {
        HStack(spacing: 4) {
            CameraModeShortcut(mode: .barcode, iconName: "barcodeIcon", title: "바코드")
            CameraModeShortcut(mode: .receipt, iconName: "receiptIcon", title: "영수증")
            CameraModeShortcut(mode: .aiVision, iconName: "aiIcon", title: "AI인식")
            CameraModeShortcut(mode: .manual, iconName: "editIcon", title: "직접입력")
        }
    }
}

struct CameraModeShortcut: View {
    let mode: CameraMode
    let iconName: String
    let title: String
    var body: some View {
        Link(destination: cameraURL(mode: mode)) {
            VStack(spacing: 6) {
                Image(iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                Text(title)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}


private func cameraURL(mode: CameraMode) -> URL {
    var components = URLComponents()
    components.scheme = DeepLink.Scheme.main
    components.host = DeepLink.Host.camera
    components.queryItems = [
        URLQueryItem(name: DeepLink.Query.mode, value: mode.rawValue)
    ]
    return components.url ?? URL(string: "jaengyeo://camera")!
}
