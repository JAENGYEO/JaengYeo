//
//  ProductEntity+CoreDataProperties.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/2/26.
//
//

import Foundation
import CoreData


public typealias ProductEntityCoreDataPropertiesSet = NSSet

extension ProductEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProductEntity> {
        return NSFetchRequest<ProductEntity>(entityName: "ProductEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var userId: String
    @NSManaged public var name: String
    @NSManaged public var quantity: Int32
    @NSManaged public var quantityUnit: String?
    @NSManaged public var mainCategory: String
    @NSManaged public var midCategoryId: UUID?
    @NSManaged public var subCategoryId: UUID?
    @NSManaged public var purchaseDate: Date?
    @NSManaged public var expiryDate: Date?
    @NSManaged public var price: Int32
    @NSManaged public var locationMemo: String?
    @NSManaged public var memo: String?
    @NSManaged public var imageUrl: String?
    @NSManaged public var isClassified: Bool
    @NSManaged public var lowStockThreshold: Int32
    @NSManaged public var isFavorite: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var syncStatus: String
    @NSManaged public var isLowStockNotificationEnabled: Bool
    @NSManaged public var caution: String?
    @NSManaged public var brand: String?

}

extension ProductEntity : Identifiable {

}
