//
//  LowStockWidget.swift
//  JaengYeoWidgetExtension
//
//  Created by 손영빈 on 5/1/26.
//

import WidgetKit
import SwiftUI

struct LowStockEntry: TimelineEntry {
    let date: Date
    let items: [InfoListItem]
}

struct LowstockProvider: TimelineProvider {
    func placeholder(in context: Context) -> LowStockEntry {
        LowStockEntry(date: Date(), items: [
            InfoListItem(id: UUID(), name: "상품", value: "1", valueSuffix: "개")
        ])
    }
    func getSnapshot(in context: Context, completion: @escaping (LowStockEntry) -> Void) {
        completion(makeEntry())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<LowStockEntry>) -> Void) {
        let entry = makeEntry()
        completion(Timeline(entries: [entry], policy: .never))
    }
    
    private func makeEntry() -> LowStockEntry {
        let store = WidgetDataStore()
        let products = store.fetchLowStockProducts()
        let items = products.map {
            InfoListItem(id: $0.id, name: $0.name, value: "\($0.quantity)", valueSuffix: "개")
        }
        return LowStockEntry(date: Date(), items: items)
    }
}

struct LowStockWidget: Widget {
    let kind = "LowStockWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LowstockProvider()) { entry in
            InfoListWidgetView(
                title: "재고 부족",
                items: entry.items,
                deepLink: URL(string: "jaengyeo://list/lowStock")!,
                emptyMessage: "재고 부족 상품이 없습니다"
            )
        }
        .configurationDisplayName("재고 부족")
        .description("재고가 부족한 상품을 확인합니다")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
