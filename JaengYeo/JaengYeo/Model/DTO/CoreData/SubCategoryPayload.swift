//
//  SubCategoryPayload.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/6/26.
//

import Foundation

/// 소분류  Payload 구조체
struct SubCategoryPayload {
    let id: UUID
    let userId: String?
    let mainCategory: String
    let name: String
    let iconName: String?
    let thumbnailKey: String?
    let sortOrder: Int32
    let createdAt: Date
    let updatedAt: Date
    let syncStatus: String
}

//MARK: - Method
extension SubCategoryPayload {
    // SubCategoryPayload -> SubCategory 변환 메소드
    func toDomain() -> SubCategory {
        SubCategory(
            id: id,
            userId: userId,
            mainCategory: mainCategory,
            name: name,
            iconName: iconName,
            thumbnailKey: thumbnailKey,
            sortOrder: Int(sortOrder),
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncStatus: syncStatus
        )
    }
}
