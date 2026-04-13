//
//  ProductDTO.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/6/26.
//

import Foundation

struct ProductDTO: Codable {
    let id: UUID
    let userId: UUID
    let name: String
    let quantity: Int
    let quantityUnit: String?
    let mainCategory: String
    let midCategoryId: UUID?
    let subCategoryId: UUID?
    let purchaseDate: Date?
    let expiryDate: Date?
    let price: Int
    let locationMemo: String?
    let memo: String?
    let imageUrl: String?
    let isClassified: Bool
    let isLowStockNotificationEnabled: Bool
    let lowStockThreshold: Int
    let isFavorite: Bool
    let createdAt: Date
    let updatedAt: Date
    let caution: String?
    let brand: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, quantity, price, memo, caution, brand
        case userId = "user_id"
        case quantityUnit = "quantity_unit"
        case mainCategory = "main_category"
        case midCategoryId = "mid_category_id"
        case subCategoryId = "sub_category_id"
        case purchaseDate = "purchase_date"
        case expiryDate = "expiry_date"
        case locationMemo = "location_memo"
        case imageUrl = "image_url"
        case isClassified = "is_classified"
        case isLowStockNotificationEnabled = "is_low_stock_notification_enabled"
        case lowStockThreshold = "low_stock_threshold"
        case isFavorite = "is_favorite"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// Supabase 응답 -> Product 도메인 변경
extension ProductDTO {
    func toDomain() -> Product {
        Product(
            id: id,
            userId: userId,
            name: name,
            quantity: quantity,
            quantityUnit: quantityUnit,
            mainCategory: mainCategory == "food" ? "식재료" : "생활용품",
            midCategoryId: midCategoryId,
            subCategoryId: subCategoryId,
            purchaseDate: purchaseDate,
            expiryDate: expiryDate,
            price: price,
            locationMemo: locationMemo,
            memo: memo,
            imageUrl: imageUrl,
            isClassified: isClassified,
            lowStockThreshold: lowStockThreshold,
            isFavorite: isFavorite,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncStatus: SyncStatus.synced.rawValue, // 서버에서 받아온 데이터는 synced 상태
            isLowStockNotificationEnabled: isLowStockNotificationEnabled,
            caution: caution,
            brand: brand
        )
    }
}

// 도메인 -> Supabase 업로드
extension ProductDTO {
    init(from product: Product) {
        self.id = product.id
        self.userId = product.userId
        self.name = product.name
        self.quantity = product.quantity
        self.quantityUnit = product.quantityUnit
        self.mainCategory = product.mainCategory == "식재료" ? "food" : "household"
        self.midCategoryId = product.midCategoryId
        self.subCategoryId = product.subCategoryId
        self.purchaseDate = product.purchaseDate
        self.expiryDate = product.expiryDate
        self.price = product.price
        self.locationMemo = product.locationMemo
        self.memo = product.memo
        self.imageUrl = product.imageUrl
        self.isClassified = product.isClassified
        self.lowStockThreshold = product.lowStockThreshold
        self.isFavorite = product.isFavorite
        self.createdAt = product.createdAt
        self.updatedAt = product.updatedAt
        self.isLowStockNotificationEnabled = product.isLowStockNotificationEnabled
        self.caution = product.caution
        self.brand = product.brand
    }
}
