//
//  SubCategory.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/6/26.
//

import Foundation

struct SubCategory {
    let id: UUID
    let userId: String?
    let mainCategory: String
    let name: String
    let iconName: String?
    let thumbnailKey: String?
    let sortOrder: Int
    let createdAt: Date
    let updatedAt: Date
    let syncStatus: String
}

//MARK: - Method
extension SubCategory {
    /// SubCategory -> SubCategoryPayload 변환 메소드
    func toPayload() -> SubCategoryPayload {
        SubCategoryPayload(
            id: id,
            userId: userId,
            mainCategory: mainCategory,
            name: name,
            iconName: iconName,
            thumbnailKey: thumbnailKey,
            sortOrder: Int32(sortOrder),
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncStatus: syncStatus
        )
    }
}
