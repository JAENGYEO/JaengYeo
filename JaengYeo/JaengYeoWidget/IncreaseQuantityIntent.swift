//
//  IncreaseQuantityIntent.swift
//  JaengYeoWidgetExtension
//
//  Created by 손영빈 on 5/1/26.
//

import WidgetKit
import AppIntents

struct IncreaseQuantityIntent: AppIntent {
    static var title: LocalizedStringResource = "수량 증가"
    
    @Parameter(title: "상품 ID")
    var productID: String
    
    init() {}
    
    init(productID: UUID) {
        self.productID = productID.uuidString
    }
    
    func perform() async throws -> some IntentResult {
        guard let id = UUID(uuidString: productID) else { return .result() }
        await MainActor.run {
            _ = WidgetDataStore().updateQuantity(productID: id, delta: 1)
        }
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
