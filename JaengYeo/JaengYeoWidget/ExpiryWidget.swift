//
//  ExpiryWidget.swift
//  JaengYeoWidgetExtension
//
//  Created by 손영빈 on 5/1/26.
//

import WidgetKit
import SwiftUI

struct ExpiryEntry: TimelineEntry {
    let date: Date
    let items: [InfoListItem]
}

struct ExpiryProvider: TimelineProvider {
    func placeholder(in context: Context) -> ExpiryEntry {
        ExpiryEntry(date: Date(), items: [
            InfoListItem(id: UUID(), name: "상품", value: "D-day", valueSuffix: nil)
        ])
    }
    func getSnapshot(in context: Context, completion: @escaping (ExpiryEntry) -> Void) {
        completion(makeEntry())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<ExpiryEntry>) -> Void) {
        let entry = makeEntry()
        completion(Timeline(entries: [entry], policy: .never))
    }
    
    private func makeEntry() -> ExpiryEntry {
        let store = WidgetDataStore()
        let products = store.fetchExpiryImminentProducts()
        let items = products.map {
            InfoListItem(
                id: $0.id,
                name: $0.name,
                value: $0.daysLeft == 0 ? "D-day" : "D-\($0.daysLeft)",
                valueSuffix: nil
            )
        }
        return ExpiryEntry(date: Date(), items: items)
    }
}

struct ExpiryWidget: Widget {
    let kind = "ExpiryWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ExpiryProvider()) { entry in
            InfoListWidgetView(
                title: "유통기한 임박",
                items: entry.items,
                deepLink: URL(string: "jaengyeo://list/expiry")!,
                emptyMessage: "유통기한 임박 상품이 없습니다"
            )
        }
        .configurationDisplayName("유통기한 임박")
        .description("유통기한이 임박한 상품을 확인합니다")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
