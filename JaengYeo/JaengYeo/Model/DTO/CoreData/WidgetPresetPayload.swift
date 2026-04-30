//
//  WidgetPresetPayload.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/30/26.
//

import Foundation

struct WidgetPresetPayload: Hashable {
    let id: UUID
    let name: String
    let productIDs: [UUID]
    let createdAt: Date
    let updatedAt: Date
}
