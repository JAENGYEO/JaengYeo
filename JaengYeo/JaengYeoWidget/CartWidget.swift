//
//  CartWidget.swift
//  JaengYeoWidgetExtension
//
//  Created by 손영빈 on 5/4/26.
//

import WidgetKit
import SwiftUI

struct CartEntry: TimelineEntry {
    let date: Date
    let items: [InfoListItem]
}

struct CartProvider: TimelineProvider {
    func placeholder(in context: Context) -> CartEntry {
        CartEntry(
            date: Date(),
            items: [
                InfoListItem(id: UUID(), name: "상품", value: "1", valueSuffix: "개")
        ])
    }
    func getSnapshot(in context: Context, completion: @escaping (CartEntry) -> Void) {
        completion(makeEntry())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<CartEntry>) -> Void) {
        let entry = makeEntry()
        completion(Timeline(entries: [entry], policy: .never))
    }
    private func makeEntry() -> CartEntry {
        let items = WidgetDataStore().fetchCartItems()
        return CartEntry(date: Date(), items: items)
    }
}

struct CartWidget: Widget {
    let kind = "CartWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CartProvider()) { entry in
            InfoListWidgetView(
                title: "구매 예정 목록",
                items: entry.items,
                deepLink: URL(string: "jaengyeo://cart")!,
                emptyMessage: "구매 예정 목록이 비어있습니다"
            )
        }
        .configurationDisplayName("구매 예정 목록")
        .description("구매 예정 상품을 확인합니다")
        .supportedFamilies([.systemMedium])
    }
}
