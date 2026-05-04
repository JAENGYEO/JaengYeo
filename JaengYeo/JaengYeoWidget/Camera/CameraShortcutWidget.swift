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
        }
        .configurationDisplayName("물품 등록")
        .description("탭으로 등록 화면 진입")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct CameraShortcutWidgetView: View {
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme
    let entry: CameraShortcutEntry

    private var textColor: Color {
        colorScheme == .dark ? .white : Color(red: 0.2, green: 0.2, blue: 0.2)
    }

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                CameraShortcutSmallView(textColor: textColor)
            case .systemMedium:
                CameraShortcutMediumView(textColor: textColor)
            default:
                CameraShortcutSmallView(textColor: textColor)
            }
        }
        .containerBackground(for: .widget) {
            colorScheme == .dark ? Color(red: 0.1, green: 0.1, blue: 0.1) : Color.white
        }
    }
}

struct CameraShortcutSmallView: View {
    let textColor: Color

    var body: some View {
        Link(destination: cameraURL(mode: .barcode)) {
            VStack(spacing: 16) {
                HStack {
                    Text("물품 등록")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(textColor)
                    Spacer()
                    Image("CameraLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 22)
                }
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                    Image("CameraIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                        .foregroundColor(textColor)
                }
            }
            .padding(16)
        }
    }
}

struct CameraShortcutMediumView: View {
    let textColor: Color

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text("물품 등록")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(textColor)
                Spacer()
                Image("widgetLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 22)
            }
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    CameraModeButton(mode: .barcode, iconName: "barcodeIcon", title: "바코드", textColor: textColor)
                    CameraModeButton(mode: .receipt, iconName: "receiptIcon", title: "영수증", textColor: textColor)
                    CameraModeButton(mode: .aiVision, iconName: "aiIcon", title: "AI인식", textColor: textColor)
                }
                Link(destination: cameraURL(mode: .manual)) {
                    HStack(spacing: 4) {
                        Image("editIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                        Text("직접입력")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(textColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
}

struct CameraModeButton: View {
    let mode: CameraMode
    let iconName: String
    let title: String
    let textColor: Color

    var body: some View {
        Link(destination: cameraURL(mode: mode)) {
            VStack(spacing: 4) {
                Image(iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(textColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 8))
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
