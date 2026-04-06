//
//  MidCategoryPayload.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/6/26.
//

import Foundation

/// 중분류  Payload 구조체
struct MidCategoryPayload {
    let id: UUID
    let userId: String?
    let mainCategory: String
    let name: String
    let iconName: String?
    let sortOrder: Int32
    let createdAt: Date
    let updatedAt: Date
    let syncStatus: String
}

//MARK: - Method
extension MidCategoryPayload {
    // MidCategoryPayload -> MidCategory 변환 메소드
    func toDomain() -> MidCategory {
        MidCategory(
            id: id,
            userId: userId,
            mainCategory: mainCategory,
            name: name,
            iconName: iconName,
            sortOrder: Int(sortOrder),
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncStatus: syncStatus
        )
    }
}
