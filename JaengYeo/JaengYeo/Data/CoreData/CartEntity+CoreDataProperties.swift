//
//  CartEntity+CoreDataProperties.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/28/26.
//
//

import Foundation
import CoreData


public typealias CartEntityCoreDataPropertiesSet = NSSet

extension CartEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CartEntity> {
        return NSFetchRequest<CartEntity>(entityName: "CartEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var referenceId: UUID?
    @NSManaged public var name: String?
    @NSManaged public var mainCategory: String?
    @NSManaged public var createDate: Date?

}

extension CartEntity : Identifiable {

}

extension CartEntity {
    var toDomain: Cart {
        Cart(
            id: id ?? UUID(),
            referenceId: referenceId,
            name: name ?? "",
            mainCategory: mainCategory ?? "",
            createdAt: createDate
        )
    }
}
