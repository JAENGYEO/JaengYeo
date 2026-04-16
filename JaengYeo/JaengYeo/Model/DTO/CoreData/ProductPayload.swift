//
//  ProductPayload.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/6/26.
//

import UIKit

/// 상품 데이터 Payload 구조체
struct ProductPayload {
    let id: UUID
    let userId: UUID
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
    let caution: String?
    let brand: String?
}

//MARK: - Register
extension ProductPayload {
    func toRegisterFormData(midCategoryName: String?, subCategoryData: SubCategoryPayload?) -> RegisterFormData {
        var form = RegisterFormData()
        form.name = name
        form.mainCategory = mainCategory
        form.midCategory = midCategoryId
        form.midCategoryName = midCategoryName
        form.subCategory = subCategoryId
        form.subCategoryName = subCategoryData?.name
        form.subCategoryIconName = subCategoryData?.iconName
        form.quantity = Int(quantity)
        form.quantityUnit = quantityUnit
        form.purchaseDate = purchaseDate
        form.expiryDate = expiryDate
        form.memo = memo
        form.caution = caution
        form.brand = brand
        form.imageUrl = imageUrl
        form.lowStockThreshold = Int(lowStockThreshold)
        form.isLowStockNotificationEnabled = isLowStockNotificationEnabled

        var fields: Set<RegisterOptionField> = []
        if subCategoryId != nil { fields.insert(.subCategory) }
        if imageUrl != nil { fields.insert(.photo) }
        if expiryDate != nil { fields.insert(.expiryDate) }
        if caution != nil { fields.insert(.caution) }
        if brand != nil { fields.insert(.brand) }
        if memo != nil { fields.insert(.memo) }
        if isLowStockNotificationEnabled { fields.insert(.stockAlert) }
        form.selectedFields = fields

        return form
    }

    func updated(with item: RegisterFormData, imageUrl: String?) -> ProductPayload {
        ProductPayload(
            id: id,
            userId: userId,
            name: item.name ?? name,
            quantity: Int32(item.quantity ?? Int(quantity)),
            quantityUnit: item.quantityUnit ?? quantityUnit,
            mainCategory: item.mainCategory ?? mainCategory,
            midCategoryId: item.midCategory,
            subCategoryId: item.subCategory,
            purchaseDate: item.purchaseDate,
            expiryDate: item.expiryDate,
            price: price,
            locationMemo: locationMemo,
            memo: item.memo,
            imageUrl: imageUrl,
            isClassified: item.mainCategory != nil,
            lowStockThreshold: Int32(item.lowStockThreshold ?? Int(lowStockThreshold)),
            isFavorite: isFavorite,
            createdAt: createdAt,
            updatedAt: Date(),
            syncStatus: SyncStatus.pendingUpload.rawValue,
            isLowStockNotificationEnabled: item.isLowStockNotificationEnabled ?? isLowStockNotificationEnabled,
            caution: item.caution,
            brand: item.brand
        )
    }
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
            isLowStockNotificationEnabled: isLowStockNotificationEnabled,
            caution: caution,
            brand: brand
        )
    }
}
