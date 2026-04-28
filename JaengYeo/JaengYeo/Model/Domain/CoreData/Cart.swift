//
//  Cart.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/28/26.
//

import Foundation
import CoreData

struct Cart: Hashable {
    let id: UUID
    let referenceId: UUID?
    let name: String
    let mainCategory: String
    let createdAt: Date?
}

extension Cart {
    func toEntity(context: NSManagedObjectContext) -> CartEntity {
        let entity = CartEntity(context: context)
        entity.id = id
        entity.referenceId = referenceId
        entity.name = name
        entity.mainCategory = mainCategory
        entity.createDate = createdAt

        return entity
    }
}

