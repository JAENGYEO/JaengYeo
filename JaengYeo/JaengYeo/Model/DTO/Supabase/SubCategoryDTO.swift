//
//  SubCategoryDTO.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/6/26.
//

import Foundation

//TODO: 받아온 데이터 모델로 변환하는 메서드 생성 필요, CoreData 브랜치 병합 후 진행할 예정
struct SubCategoryDTO: Codable {
    let id: UUID
    let userId: String?
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
