//
//  InfoListWidgetView.swift
//  JaengYeoWidgetExtension
//
//  Created by 손영빈 on 5/1/26.
//

import WidgetKit
import SwiftUI

struct InfoListItem: Identifiable {
    let id: UUID
    let name: String
    let value: String
    let valueSuffix: String?
}

struct InfoListWidgetView: View {
    let title: String
    let items: [InfoListItem]
    let deepLink: URL
    let emptyMessage: String
    
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme
    
    private var textColor: Color {
        colorScheme == .dark ? .white : Color(red: 0.2, green: 0.2, blue: 0.2)
    }
    
    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                smallView
            case .systemMedium:
                mediumView
            default:
                smallView
            }
        }
        .containerBackground(for: .widget) {
            colorScheme == .dark ? Color(red: 0.1, green: 0.1, blue: 0.1) : Color.white
        }
        .widgetURL(deepLink)
    }
    
    private var smallView: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerView(logoName: "CameraLogo", logoHeight: 22)
            if items.isEmpty {
                Spacer(minLength: 0)
                Text(emptyMessage)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                Spacer(minLength: 0)
            } else {
                VStack(spacing: 12) {
                    ForEach(items.prefix(3)) { item in
                        itemRow(item: item)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding(16)
    }
    
    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerView(logoName: "widgetLogo", logoHeight: 22)
            if items.isEmpty {
                Spacer(minLength: 0)
                Text(emptyMessage)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
                    .frame(maxWidth: .infinity)
                Spacer(minLength: 0)
            } else {
                HStack(spacing: 12) {
                    VStack(spacing: 12) {
                        ForEach(leftColumItems) { item in
                            itemRow(item: item)
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity)
                    Divider()
                        .frame(width: 1)
                        .background(Color.gray.opacity(0.3))
                    VStack(spacing: 12) {
                        ForEach(rightColumItems) { item in
                            itemRow(item: item)
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
    
    private func headerView(logoName: String, logoHeight: CGFloat) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(textColor)
            Spacer()
            Image(logoName)
                .resizable()
                .scaledToFit()
                .frame(height: logoHeight)
        }
    }
    
    private func itemRow(item: InfoListItem) -> some View {
        HStack {
            Text(item.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(textColor)
                .lineLimit(1)
            Spacer()
            HStack(spacing: 0) {
                Text(item.value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.accentColor)
                if let suffix = item.valueSuffix {
                    Text(suffix)
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
                }
            }
        }
    }
    
    private var leftColumItems: [InfoListItem] {
        Array(items.prefix(3))
    }
    
    private var rightColumItems: [InfoListItem] {
        Array(items.dropFirst(3).prefix(3))
    }
}
