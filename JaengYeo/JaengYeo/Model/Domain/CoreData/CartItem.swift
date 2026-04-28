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
    let createdAt: Date?
}

extension CartItem {
    func toEntity(context: NSManagedObjectContext) -> CartItemEntity {
        let entity = CartItemEntity(context: context)
        entity.id = id
        entity.referenceId = referenceId
        entity.name = name
        entity.mainCategory = mainCategory
        entity.createDate = createdAt

        return entity
    }
}

