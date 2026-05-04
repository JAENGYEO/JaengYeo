//
//  WidgetPresetAppEntity.swift
//  JaengYeoWidgetExtension
//
//  Created by 손영빈 on 5/1/26.
//

import AppIntents

struct WidgetPresetAppEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "위젯 프리셋")
    static var defaultQuery = WidgetPresetEntityQuery()
    
    var id: UUID
    var name: String
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}
