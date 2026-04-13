//
//  MidCategoryDTO.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/6/26.
//

import Foundation

struct MidCategoryDTO: Codable {
    let id: UUID
    let userId: UUID?
    let mainCategory: String
    let name: String
    let iconName: String?
    let sortOrder: Int
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case userId = "user_id"
        case mainCategory = "main_category"
        case iconName = "icon_name"
        case sortOrder = "sort_order"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// Supabase -> MidCategory 변경
extension MidCategoryDTO {
    func toDomain() -> MidCategory {
        MidCategory(
            id: id,
            userId: userId,
            mainCategory: mainCategory,
            name: name,
            iconName: iconName,
            sortOrder: sortOrder,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncStatus: SyncStatus.synced.rawValue
        )
    }
}

// 도메인 -> Supabase
extension MidCategoryDTO {
    init(from midCategory: MidCategory) {
        self.id = midCategory.id
        self.userId = midCategory.userId
        self.mainCategory = midCategory.mainCategory
        self.name = midCategory.name
        self.iconName = midCategory.iconName
        self.sortOrder = midCategory.sortOrder
        self.createdAt = midCategory.createdAt
        self.updatedAt = midCategory.updatedAt
    }
}
