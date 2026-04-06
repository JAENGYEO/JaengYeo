//
//  ProductPayload.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/6/26.
//

import Foundation

/// 상품 데이터 Payload 구조체
struct ProductPayload {
    let id: UUID
    let userId: String
    let name: String
    let quantity: Int32
    let quantityUnit: String?
    let mainCategory: String
    let midCategoryId: UUID?
    let subCategoryId: UUID?
    let purchaseDate: Date?
    let expiryDate: Date?
    let price: Int32
    let locationMemo: String?
    let memo: String?
    let imageUrl: String?
    let isClassified: Bool
    let lowStockThreshold: Int32
    let isFavorite: Bool
    let createdAt: Date
    let updatedAt: Date
    let syncStatus: String
    let isLowStockNotificationEnabled: Bool
}

//MARK: - Method
extension ProductPayload {
    // ProductPayload -> Product 변환 메소드
    func toDomain() -> Product {
        Product(
            id: id,
            userId: userId,
            name: name,
            quantity: Int(quantity),
            quantityUnit: quantityUnit,
            mainCategory: mainCategory,
            midCategoryId: midCategoryId,
            subCategoryId: subCategoryId,
            purchaseDate: purchaseDate,
            expiryDate: expiryDate,
            price: Int(price),
            locationMemo: locationMemo,
            memo: memo,
            imageUrl: imageUrl,
            isClassified: isClassified,
            lowStockThreshold: Int(lowStockThreshold),
            isFavorite: isFavorite,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncStatus: syncStatus,
            isLowStockNotificationEnabled: isLowStockNotificationEnabled
        )
    }
}
