//
//  RegisterFormData.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/8/26.
//

import Foundation

//TODO: 추후 Entity 저장 로직 구현 시 수정 필요
struct RegisterFormData: Hashable {
    let id: UUID = UUID()
    var name: String?
    var mainCategory: String?
    var midCategory: UUID?
    var subCategory: UUID?
    var quantity: Int?
    var quantityUnit: String?
    var price: Int?
    var purchaseDate: Date?
    var expiryDate: Date?
    var locationMemo: String?
    var memo: String?
    var imageBase64: String?
    var isLowStockNotificationEnabled: Bool?
    var lowStockThreshold: Int?
    var caution: String?
    var brand: String?
    var selectedFields: Set<RegisterOptionField> = []
}
