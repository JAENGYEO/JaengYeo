//
//  CartItemEntity+CoreDataProperties.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/28/26.
//
//

import Foundation
import CoreData


public typealias CartItemEntityCoreDataPropertiesSet = NSSet

extension CartItemEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CartItemEntity> {
        return NSFetchRequest<CartItemEntity>(entityName: "CartItemEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var referenceId: UUID?
    @NSManaged public var name: String?
    @NSManaged public var mainCategory: String?
    @NSManaged public var quantity: Int32
    @NSManaged public var createDate: Date?

}

extension CartItemEntity : Identifiable {

}

extension CartItemEntity {
    var toDomain: CartItem {
        CartItem(
            id: id ?? UUID(),
            referenceId: referenceId,
            name: name ?? "",
            mainCategory: mainCategory ?? "",
            quantity: Int(quantity),
            createdAt: createDate
        )
    }
}
