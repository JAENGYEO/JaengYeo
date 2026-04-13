//
//  SubCategoryDTO.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/6/26.
//

import Foundation

struct SubCategoryDTO: Codable {
    let id: UUID
    let userId: UUID?
    let mainCategory: String
    let name: String
    let iconName: String?
    let thumbnailKey: String?
    let sortOrder: Int
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case userId = "user_id"
        case mainCategory = "main_category"
        case iconName = "icon_name"
        case thumbnailKey = "thumbnail_key"
        case sortOrder = "sort_order"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// Supabase -> Domain
extension SubCategoryDTO {
    func toDomain() -> SubCategory {
        SubCategory(
            id: id,
            userId: userId,
            mainCategory: mainCategory,
            name: name,
            iconName: iconName,
            thumbnailKey: thumbnailKey,
            sortOrder: sortOrder,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncStatus: SyncStatus.synced.rawValue
        )
    }
}

// Domain -> Supabase
extension SubCategoryDTO {
    init(from subCategory: SubCategory) {
        self.id = subCategory.id
        self.userId = subCategory.userId
        self.mainCategory = subCategory.mainCategory
        self.name = subCategory.name
        self.iconName = subCategory.iconName
        self.thumbnailKey = subCategory.thumbnailKey
        self.sortOrder = subCategory.sortOrder
        self.createdAt = subCategory.createdAt
        self.updatedAt = subCategory.updatedAt
    }
}
