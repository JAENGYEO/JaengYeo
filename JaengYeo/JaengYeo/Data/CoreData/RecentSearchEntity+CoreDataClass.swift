//
//  RecentSearchEntity+CoreDataClass.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/23/26.
//
//

public import Foundation
public import CoreData

public typealias RecentSearchEntityCoreDataClassSet = NSSet

@objc(RecentSearchEntity)
public class RecentSearchEntity: NSManagedObject {
    static let className = "RecentSearchEntity"
}
