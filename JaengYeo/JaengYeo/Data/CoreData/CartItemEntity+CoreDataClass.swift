//
//  CartItemEntity+CoreDataClass.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/28/26.
//
//

import Foundation
import CoreData

public typealias CartItemEntityCoreDataClassSet = NSSet

@objc(CartItemEntity)
public class CartItemEntity: NSManagedObject {
    static let className = "CartItemEntity"

}
