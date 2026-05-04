//
//  WidgetDataStore.swift
//  JaengYeoWidgetExtension
//
//  Created by 손영빈 on 5/1/26.
//

import CoreData
import Foundation

struct WidgetPresetInfo {
    let id: UUID
    let name: String
    let productIDs: [UUID]
}

struct WidgetProductInfo {
    let id: UUID
    let name: String
    let quantity: Int
    let imageUrl: String?
}

struct WidgetExpiryItem {
    let id: UUID
    let name: String
    let daysLeft: Int
}

final class WidgetDataStore {
    private static let container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "JaengYeo")
        let storeURL = sharedStoreURL()
        let description = NSPersistentStoreDescription(url: storeURL)
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, _ in }
        return container
    }()

    private var context: NSManagedObjectContext { Self.container.viewContext }
    private static func sharedStoreURL() -> URL {
        guard let url = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.jaengyoeo.JaengYeo"
        ) else {
            fatalError("Unable to get the shared container URL")
        }
        return url.appendingPathComponent("JaengYeo.sqlite")
    }
}

// MARK: - Read
extension WidgetDataStore {
    func fetchAllPresets() -> [WidgetPresetInfo] {
        let request = WidgetPresetEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        let results = (try? context.fetch(request)) ?? []
        return results.compactMap { entity in
            guard let ids = try? JSONDecoder().decode([UUID].self, from: entity.productIDsData) else { return nil }
            return WidgetPresetInfo(id: entity.id, name: entity.name, productIDs: ids)
        }
    }
    
    func fetchPreset(id: UUID) -> WidgetPresetInfo? {
        let request = WidgetPresetEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as NSUUID)
        request.fetchLimit = 1
        guard let entity = (try? context.fetch(request))?.first,
              let ids = try? JSONDecoder().decode([UUID].self, from: entity.productIDsData) else { return nil }
        return WidgetPresetInfo(id: entity.id, name: entity.name, productIDs: ids)
    }
    
    func fetchProducts(ids: [UUID]) -> [WidgetProductInfo] {
        guard !ids.isEmpty else { return [] }
        let request = NSFetchRequest<NSManagedObject>(entityName: ProductEntity.className)
        request.predicate = NSPredicate(format: "id IN %@", ids.map { $0 as NSUUID })
        let results = (try? context.fetch(request)) ?? []
        
        let mapped = results.compactMap { obj -> WidgetProductInfo? in
            guard let id = obj.value(forKey: ProductEntity.Keys.id) as? UUID,
                  let name = obj.value(forKey: ProductEntity.Keys.name) as? String else { return nil }
            let quantity = obj.value(forKey: ProductEntity.Keys.quantity) as? Int32 ?? 0
            let imageUrl = obj.value(forKey: ProductEntity.Keys.imageUrl) as? String
            return WidgetProductInfo(id: id, name: name, quantity: Int(quantity), imageUrl: imageUrl)
        }
        let idOrder = Dictionary(uniqueKeysWithValues: ids.enumerated().map { ($1, $0) })
        return mapped.sorted { (idOrder[$0.id] ?? 0) < (idOrder[$1.id] ?? 0 )}
    }
    
    func fetchLowStockProducts(limit: Int = 6) -> [WidgetProductInfo] {
        let request = NSFetchRequest<NSManagedObject>(entityName: ProductEntity.className)
        request.predicate = NSPredicate(format: "isLowStockNotificationEnabled == true AND quantity <= lowStockThreshold AND syncStatus != %@", "pendingDelete")
        request.sortDescriptors = [NSSortDescriptor(key: "quantity", ascending: true)]
        request.fetchLimit = limit
        let results = (try? context.fetch(request)) ?? []
        return results.compactMap { obj in
            guard let id = obj.value(forKey: ProductEntity.Keys.id) as? UUID,
                  let name = obj.value(forKey: ProductEntity.Keys.name) as? String else { return nil }
            let quantity = obj.value(forKey: ProductEntity.Keys.quantity) as? Int32 ?? 0
            return WidgetProductInfo(id: id, name: name, quantity: Int(quantity), imageUrl: nil)
        }
    }
    
    func fetchExpiryImminentProducts(days: Int = 3, limit: Int = 6) -> [WidgetExpiryItem] {
        let today = Calendar.current.startOfDay(for: Date())
        guard let deadline = Calendar.current.date(byAdding: .day, value: days + 1, to: today) else { return [] }
        let request = NSFetchRequest<NSManagedObject>(entityName: ProductEntity.className)
        request.predicate = NSPredicate(
            format: "expiryDate >= %@ AND expiryDate < %@ AND syncStatus != %@",
            today as NSDate, deadline as NSDate, "pendingDelete"
        )
        request.sortDescriptors = [NSSortDescriptor(key: "expiryDate", ascending: true)]
        request.fetchLimit = limit
        let results = (try? context.fetch(request)) ?? []
        return results.compactMap { obj in
            guard let id = obj.value(forKey: ProductEntity.Keys.id) as? UUID,
                  let name = obj.value(forKey: ProductEntity.Keys.name) as? String,
                  let expiryDate = obj.value(forKey: ProductEntity.Keys.expiryDate) as? Date else { return nil }
            let daysLeft = Calendar.current.dateComponents([.day], from: today, to: Calendar.current.startOfDay(for: expiryDate)).day ?? 0
            return WidgetExpiryItem(id: id, name: name, daysLeft: daysLeft)
        }
    }
    
    func fetchCartItems(limit: Int = 6) -> [InfoListItem] {
        let request = NSFetchRequest<NSManagedObject>(entityName: CartItemEntity.className)
        request.sortDescriptors = [NSSortDescriptor(key: "createDate", ascending: false)]
        request.fetchLimit = limit
        let results = (try? context.fetch(request)) ?? []
        return results.compactMap { obj in
            guard let id = obj.value(forKey: "id") as? UUID,
                  let name = obj.value(forKey: "name") as? String else { return nil }
            let quantity = obj.value(forKey: "quantity") as? Int32 ?? 0
            return InfoListItem(id: id, name: name, value: "\(quantity)", valueSuffix: "개")
        }
    }
}

// MARK: - Write
extension WidgetDataStore {
    @discardableResult
    func updateQuantity(productID: UUID, delta: Int) -> Int? {
        let request = NSFetchRequest<NSManagedObject>(entityName: ProductEntity.className)
        request.predicate = NSPredicate(format: "id == %@", productID as NSUUID)
        request.fetchLimit = 1
        guard let entity = (try? context.fetch(request))?.first else { return nil }
        
        let current = entity.value(forKey: ProductEntity.Keys.quantity) as? Int32 ?? 0
        let newQuantity = max(0, min(Int(current) + delta, 999))
        entity.setValue(Int32(newQuantity), forKey: ProductEntity.Keys.quantity)
        entity.setValue(Date(), forKey: ProductEntity.Keys.updatedAt)
        entity.setValue("pendingUpload", forKey: ProductEntity.Keys.syncStatus)
        try? context.save()
        return newQuantity
    }
}
