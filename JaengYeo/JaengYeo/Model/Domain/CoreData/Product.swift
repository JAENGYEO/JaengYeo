//
//  Product.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/6/26.
//

import Foundation

struct Product: Hashable {
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
    let lowStockThreshold: Int
    let isFavorite: Bool
    let createdAt: Date
    let updatedAt: Date
    let syncStatus: String
    let isLowStockNotificationEnabled: Bool
    let caution: String?
    let brand: String?
}

//MARK: - Method
extension Product {
    /// Product -> ProductPayload 변환 메소드
    func toPayload() -> ProductPayload {
        ProductPayload(
            id: id,
            userId: userId,
            name: name,
            quantity: Int32(quantity),
            quantityUnit: quantityUnit,
            mainCategory: mainCategory,
            midCategoryId: midCategoryId,
            subCategoryId: subCategoryId,
            purchaseDate: purchaseDate,
            expiryDate: expiryDate,
            price: Int32(price),
            locationMemo: locationMemo,
            memo: memo,
            imageUrl: imageUrl,
            isClassified: isClassified,
            lowStockThreshold: Int32(lowStockThreshold),
            isFavorite: isFavorite,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncStatus: syncStatus,
            isLowStockNotificationEnabled: isLowStockNotificationEnabled,
            caution: caution,
            brand: brand
        )
    }
}

extension Product {
    /// 재고가 1개 차감된 상품 생성
    func decreasedQuantity() -> Product {
        Product(
            id: id,
            userId: userId,
            name: name,
            quantity: quantity - 1,
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
            updatedAt: Date(),
            syncStatus: SyncStatus.pendingUpload.rawValue,
            isLowStockNotificationEnabled: isLowStockNotificationEnabled,
            caution: caution,
            brand: brand
        )
    }
}
