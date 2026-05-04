//
//  QuantityWidgetIntent.swift
//  JaengYeoWidgetExtension
//
//  Created by 손영빈 on 5/1/26.
//

import AppIntents
import WidgetKit

struct QuantityWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "수량 위젯"
    static var description: IntentDescription = "프리셋을 선택하여 상품 수량을 확인합니다"
    
    @Parameter(title: "프리셋")
    var preset: WidgetPresetAppEntity?
}
