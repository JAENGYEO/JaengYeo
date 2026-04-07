//
//  ProductDTO.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/6/26.
//

import Foundation

struct ProductDTO: Codable {
    let id: UUID
    let userId: String
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
    
    enum CodingKeys: String, CodingKey {
        case id, name, quantity, price, memo
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
            mainCategory: mainCategory,
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
            isLowStockNotificationEnabled: isLowStockNotificationEnabled
        )
    }
}
