//
//  QuantityWidget.swift
//  JaengYeoWidgetExtension
//
//  Created by 손영빈 on 5/1/26.
//

import WidgetKit
import SwiftUI

struct QuantityWidgetEntry: TimelineEntry {
    let date: Date
    let presetName: String
    let products: [WidgetProductInfo]
}

struct QuantityWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> QuantityWidgetEntry {
        QuantityWidgetEntry(
            date: Date(),
            presetName: "재고 관리",
            products: [WidgetProductInfo(id: UUID(), name: "상품", quantity: 1, imageUrl: nil)]
        )
    }
    func snapshot(for configuration: QuantityWidgetIntent, in context: Context) async -> QuantityWidgetEntry {
        makeEntry(for: configuration)
    }
    func timeline(for configuration: QuantityWidgetIntent, in context: Context) async -> Timeline<QuantityWidgetEntry> {
        let entry = makeEntry(for: configuration)
        return Timeline(entries: [entry], policy: .never)
    }
    
    private func makeEntry(for configuration: QuantityWidgetIntent) -> QuantityWidgetEntry {
        let store = WidgetDataStore()
        guard let presetEntity = configuration.preset,
              let preset = store.fetchPreset(id: presetEntity.id) else {
            return QuantityWidgetEntry(date: Date(), presetName: "프리셋을 선택해주세요", products: [])
        }
        let products = store.fetchProducts(ids: preset.productIDs)
        return QuantityWidgetEntry(date: Date(), presetName: preset.name, products: products)
    }
}

struct QuantityWidget: Widget {
    let kind = "QuantityWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: QuantityWidgetIntent.self, provider: QuantityWidgetProvider()) { entry in
                QuantityWidgetView(entry: entry)
            }
            .configurationDisplayName("수량 위젯")
            .description("프리셋 상품의 수량을 확인하고 관리합니다")
            .supportedFamilies([.systemLarge])
    }
}
