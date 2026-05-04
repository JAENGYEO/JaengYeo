//
//  CartItem.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/28/26.
//

import Foundation
import CoreData

struct CartItem: Hashable {
    let id: UUID
    let referenceId: UUID?
    let name: String
    let mainCategory: String
    let quantity: Int
    let createdAt: Date?
}

extension CartItem {
    func toEntity(context: NSManagedObjectContext) -> CartItemEntity {
        let entity = CartItemEntity(context: context)
        entity.id = id
        entity.referenceId = referenceId
        entity.name = name
        entity.mainCategory = mainCategory
        entity.quantity = Int32(quantity)
        entity.createDate = createdAt

        return entity
    }
}

extension CartItem {
    static let maxQuantity = 999

    func increased() -> CartItem {
        CartItem(
            id: id,
            referenceId: referenceId,
            name: name,
            mainCategory: mainCategory,
            quantity: min(quantity + 1, Self.maxQuantity),
            createdAt: createdAt
        )
    }

    func decreased() -> CartItem {
        CartItem(
            id: id,
            referenceId: referenceId,
            name: name,
            mainCategory: mainCategory,
            quantity: max(quantity - 1, 1),
            createdAt: createdAt
        )
    }
}
