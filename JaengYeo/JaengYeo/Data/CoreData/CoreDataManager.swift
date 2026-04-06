//
//  CoreDataManager.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/6/26.
//


import CoreData
import Foundation

final class CoreDataManager {
    // MARK: CoreData 기본 설정
    private let persistentContainer: NSPersistentContainer

    init() {
        persistentContainer = NSPersistentContainer(name: "JaengYeo")
        persistentContainer.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }

    func saveContext() {
        let context = persistentContainer.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    // MARK: Custom 설정
    private var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    enum CoreDataError: Error {
        case descriptionLoadFailed
        case saveFailed
        case loadFailed
        case empty
    }
}

//MARK: - SubCategory CRUD
extension CoreDataManager {
    // MARK: SubCategory Create
    func createSubCategory(_ payload: borrowing SubCategoryPayload) throws {
        guard let entityDescription = NSEntityDescription.entity(
            forEntityName: "SubCategoryEntity",
            in: context
        ) else {
            throw CoreDataError.descriptionLoadFailed
        }

        let entity = SubCategoryEntity(entity: entityDescription, insertInto: context)

        entity.id = payload.id
        entity.userId = payload.userId
        entity.mainCategory = payload.mainCategory
        entity.name = payload.name
        entity.iconName = payload.iconName
        entity.thumbnailKey = payload.thumbnailKey
        entity.sortOrder = payload.sortOrder
        entity.createdAt = payload.createdAt
        entity.updatedAt = payload.updatedAt
        entity.syncStatus = payload.syncStatus

        do {
            try context.save()
        } catch {
            throw CoreDataError.saveFailed
        }
    }

    // MARK: SubCategory Read
    func fetchSubCategory(of id: UUID) throws -> SubCategoryPayload {
        let entity = try fetchSubCategoryEntity(of: id)

        return SubCategoryPayload(
            id: entity.id,
            userId: entity.userId,
            mainCategory: entity.mainCategory,
            name: entity.name,
            iconName: entity.iconName,
            thumbnailKey: entity.thumbnailKey,
            sortOrder: entity.sortOrder,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt,
            syncStatus: entity.syncStatus
        )
    }

    func fetchAllSubCategories() throws -> [SubCategoryPayload] {
        let request: NSFetchRequest<SubCategoryEntity> = SubCategoryEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]

        do {
            return try context.fetch(request).map {
                SubCategoryPayload(
                    id: $0.id,
                    userId: $0.userId,
                    mainCategory: $0.mainCategory,
                    name: $0.name,
                    iconName: $0.iconName,
                    thumbnailKey: $0.thumbnailKey,
                    sortOrder: $0.sortOrder,
                    createdAt: $0.createdAt,
                    updatedAt: $0.updatedAt,
                    syncStatus: $0.syncStatus
                )
            }
        } catch {
            throw CoreDataError.loadFailed
        }
    }

    // MARK: SubCategory Update
    func updateSubCategory(_ payload: borrowing SubCategoryPayload) throws {
        let entity = try fetchSubCategoryEntity(of: payload.id)

        entity.userId = payload.userId
        entity.mainCategory = payload.mainCategory
        entity.name = payload.name
        entity.iconName = payload.iconName
        entity.thumbnailKey = payload.thumbnailKey
        entity.sortOrder = payload.sortOrder
        entity.updatedAt = payload.updatedAt
        entity.syncStatus = payload.syncStatus

        do {
            try context.save()
        } catch {
            throw CoreDataError.saveFailed
        }
    }

    // MARK: SubCategory Delete
    func deleteSubCategory(of id: UUID) throws {
        let entity = try fetchSubCategoryEntity(of: id)
        context.delete(entity)

        do {
            try context.save()
        } catch {
            throw CoreDataError.saveFailed
        }
    }

    // MARK: SubCategory Private Fetch
    private func fetchSubCategoryEntity(of id: UUID) throws -> SubCategoryEntity {
        let request: NSFetchRequest<SubCategoryEntity> = SubCategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        do {
            guard let entity = try context.fetch(request).first else {
                throw CoreDataError.empty
            }
            return entity
        } catch CoreDataError.empty {
            throw CoreDataError.empty
        } catch {
            throw CoreDataError.loadFailed
        }
    }
}

//MARK: - MidCategory CRUD
extension CoreDataManager {
    // MARK: MidCategory Create
    func createMidCategory(_ payload: borrowing MidCategoryPayload) throws {
        guard let entityDescription = NSEntityDescription.entity(
            forEntityName: "MidCategoryEntity",
            in: context
        ) else {
            throw CoreDataError.descriptionLoadFailed
        }

        let entity = MidCategoryEntity(entity: entityDescription, insertInto: context)

        entity.id = payload.id
        entity.userId = payload.userId
        entity.mainCategory = payload.mainCategory
        entity.name = payload.name
        entity.iconName = payload.iconName
        entity.sortOrder = payload.sortOrder
        entity.createdAt = payload.createdAt
        entity.updatedAt = payload.updatedAt
        entity.syncStatus = payload.syncStatus

        do {
            try context.save()
        } catch {
            throw CoreDataError.saveFailed
        }
    }

    // MARK: MidCategory Read
    func fetchMidCategory(of id: UUID) throws -> MidCategoryPayload {
        let entity = try fetchMidCategoryEntity(of: id)

        return MidCategoryPayload(
            id: entity.id,
            userId: entity.userId,
            mainCategory: entity.mainCategory,
            name: entity.name,
            iconName: entity.iconName,
            sortOrder: entity.sortOrder,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt,
            syncStatus: entity.syncStatus
        )
    }

    func fetchAllMidCategories() throws -> [MidCategoryPayload] {
        let request: NSFetchRequest<MidCategoryEntity> = MidCategoryEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]

        do {
            return try context.fetch(request).map {
                MidCategoryPayload(
                    id: $0.id,
                    userId: $0.userId,
                    mainCategory: $0.mainCategory,
                    name: $0.name,
                    iconName: $0.iconName,
                    sortOrder: $0.sortOrder,
                    createdAt: $0.createdAt,
                    updatedAt: $0.updatedAt,
                    syncStatus: $0.syncStatus
                )
            }
        } catch {
            throw CoreDataError.loadFailed
        }
    }

    // MARK: MidCategory Update
    func updateMidCategory(_ payload: borrowing MidCategoryPayload) throws {
        let entity = try fetchMidCategoryEntity(of: payload.id)

        entity.userId = payload.userId
        entity.mainCategory = payload.mainCategory
        entity.name = payload.name
        entity.iconName = payload.iconName
        entity.sortOrder = payload.sortOrder
        entity.updatedAt = payload.updatedAt
        entity.syncStatus = payload.syncStatus

        do {
            try context.save()
        } catch {
            throw CoreDataError.saveFailed
        }
    }

    // MARK: MidCategory Delete
    func deleteMidCategory(of id: UUID) throws {
        let entity = try fetchMidCategoryEntity(of: id)
        context.delete(entity)

        do {
            try context.save()
        } catch {
            throw CoreDataError.saveFailed
        }
    }

    // MARK: MidCategory Private Fetch
    private func fetchMidCategoryEntity(of id: UUID) throws -> MidCategoryEntity {
        let request: NSFetchRequest<MidCategoryEntity> = MidCategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        do {
            guard let entity = try context.fetch(request).first else {
                throw CoreDataError.empty
            }
            return entity
        } catch CoreDataError.empty {
            throw CoreDataError.empty
        } catch {
            throw CoreDataError.loadFailed
        }
    }
}



//MARK: - Product CRUD
extension CoreDataManager {
    // MARK: Product Create
    func createProduct(_ payload: borrowing ProductPayload) throws {
        guard let entityDescription = NSEntityDescription.entity(
            forEntityName: "ProductEntity",
            in: context
        ) else {
            throw CoreDataError.descriptionLoadFailed
        }

        let entity = ProductEntity(entity: entityDescription, insertInto: context)

        entity.id = payload.id
        entity.userId = payload.userId
        entity.name = payload.name
        entity.quantity = payload.quantity
        entity.quantityUnit = payload.quantityUnit
        entity.mainCategory = payload.mainCategory
        entity.midCategoryId = payload.midCategoryId
        entity.subCategoryId = payload.subCategoryId
        entity.purchaseDate = payload.purchaseDate
        entity.expiryDate = payload.expiryDate
        entity.price = payload.price
        entity.locationMemo = payload.locationMemo
        entity.memo = payload.memo
        entity.imageUrl = payload.imageUrl
        entity.isClassified = payload.isClassified
        entity.lowStockThreshold = payload.lowStockThreshold
        entity.isFavorite = payload.isFavorite
        entity.createdAt = payload.createdAt
        entity.updatedAt = payload.updatedAt
        entity.syncStatus = payload.syncStatus
        entity.isLowStockNotificationEnabled = payload.isLowStockNotificationEnabled

        do {
            try context.save()
        } catch {
            throw CoreDataError.saveFailed
        }
    }

    // MARK: Product Read
    func fetchProduct(of id: UUID) throws -> ProductPayload {
        let entity = try fetchProductEntity(of: id)

        return ProductPayload(
            id: entity.id,
            userId: entity.userId,
            name: entity.name,
            quantity: entity.quantity,
            quantityUnit: entity.quantityUnit,
            mainCategory: entity.mainCategory,
            midCategoryId: entity.midCategoryId,
            subCategoryId: entity.subCategoryId,
            purchaseDate: entity.purchaseDate,
            expiryDate: entity.expiryDate,
            price: entity.price,
            locationMemo: entity.locationMemo,
            memo: entity.memo,
            imageUrl: entity.imageUrl,
            isClassified: entity.isClassified,
            lowStockThreshold: entity.lowStockThreshold,
            isFavorite: entity.isFavorite,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt,
            syncStatus: entity.syncStatus,
            isLowStockNotificationEnabled: entity.isLowStockNotificationEnabled
        )
    }

    func fetchAllProducts() throws -> [ProductPayload] {
        let request: NSFetchRequest<ProductEntity> = ProductEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]

        do {
            return try context.fetch(request).map {
                ProductPayload(
                    id: $0.id,
                    userId: $0.userId,
                    name: $0.name,
                    quantity: $0.quantity,
                    quantityUnit: $0.quantityUnit,
                    mainCategory: $0.mainCategory,
                    midCategoryId: $0.midCategoryId,
                    subCategoryId: $0.subCategoryId,
                    purchaseDate: $0.purchaseDate,
                    expiryDate: $0.expiryDate,
                    price: $0.price,
                    locationMemo: $0.locationMemo,
                    memo: $0.memo,
                    imageUrl: $0.imageUrl,
                    isClassified: $0.isClassified,
                    lowStockThreshold: $0.lowStockThreshold,
                    isFavorite: $0.isFavorite,
                    createdAt: $0.createdAt,
                    updatedAt: $0.updatedAt,
                    syncStatus: $0.syncStatus,
                    isLowStockNotificationEnabled: $0.isLowStockNotificationEnabled
                )
            }
        } catch {
            throw CoreDataError.loadFailed
        }
    }

    // MARK: Product Update
    func updateProduct(_ payload: borrowing ProductPayload) throws {
        let entity = try fetchProductEntity(of: payload.id)

        entity.userId = payload.userId
        entity.name = payload.name
        entity.quantity = payload.quantity
        entity.quantityUnit = payload.quantityUnit
        entity.mainCategory = payload.mainCategory
        entity.midCategoryId = payload.midCategoryId
        entity.subCategoryId = payload.subCategoryId
        entity.purchaseDate = payload.purchaseDate
        entity.expiryDate = payload.expiryDate
        entity.price = payload.price
        entity.locationMemo = payload.locationMemo
        entity.memo = payload.memo
        entity.imageUrl = payload.imageUrl
        entity.isClassified = payload.isClassified
        entity.lowStockThreshold = payload.lowStockThreshold
        entity.isFavorite = payload.isFavorite
        entity.updatedAt = payload.updatedAt
        entity.syncStatus = payload.syncStatus
        entity.isLowStockNotificationEnabled = payload.isLowStockNotificationEnabled

        do {
            try context.save()
        } catch {
            throw CoreDataError.saveFailed
        }
    }

    // MARK: Product Delete
    func deleteProduct(of id: UUID) throws {
        let entity = try fetchProductEntity(of: id)
        context.delete(entity)

        do {
            try context.save()
        } catch {
            throw CoreDataError.saveFailed
        }
    }

    // MARK: Product Private Fetch
    private func fetchProductEntity(of id: UUID) throws -> ProductEntity {
        let request: NSFetchRequest<ProductEntity> = ProductEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        do {
            guard let entity = try context.fetch(request).first else {
                throw CoreDataError.empty
            }
            return entity
        } catch CoreDataError.empty {
            throw CoreDataError.empty
        } catch {
            throw CoreDataError.loadFailed
        }
    }
}
