//
//  MidCategory.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/6/26.
//

import Foundation

/// 중분류 Domain
struct MidCategory {
    let id: UUID
    let userId: String?
    let mainCategory: String
    let name: String
    let iconName: String?
    let sortOrder: Int
    let createdAt: Date
    let updatedAt: Date
    let syncStatus: String
}

//MARK: - Method
extension MidCategory {
    /// MidCategory -> MidCategoryPayload 변환 메소드
    func toPayload() -> MidCategoryPayload {
        MidCategoryPayload(
            id: id,
            userId: userId,
            mainCategory: mainCategory,
            name: name,
            iconName: iconName,
            sortOrder: Int32(sortOrder),
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncStatus: syncStatus
        )
    }
}
