//
//  ProductEntity+CoreDataClass.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/2/26.
//
//

import Foundation
import CoreData

public typealias ProductEntityCoreDataClassSet = NSSet

@objc(ProductEntity)
public class ProductEntity: NSManagedObject {
    static let className = "ProductEntity"
    
    enum Keys {
        static let id = "id"
        static let userId = "userId"
        static let name = "name"
        static let quantity = "quantity"
        static let quantityUnit = "quantityUnit"
        static let mainCategory = "mainCategory"
        static let midCategoryId = "midCategoryId"
        static let subCategoryId = "subCategoryId"
        static let purchaseDate = "purchaseDate"
        static let expiryDate = "expiryDate"
        static let price = "price"
        static let locationMemo = "locationMemo"
        static let memo = "memo"
        static let imageUrl = "imageUrl"
        static let isClassified = "isClassified"
        static let lowStockThreshold = "lowStockThreshold"
        static let isFavorite = "isFavorite"
        static let createdAt = "createdAt"
        static let updatedAt = "updatedAt"
        static let syncStatus = "syncStatus"
        static let isLowStockNotificationEnabled = "isLowStockNotificationEnabled"
        static let caution = "caution"
        static let brand = "brand"
    }
}
