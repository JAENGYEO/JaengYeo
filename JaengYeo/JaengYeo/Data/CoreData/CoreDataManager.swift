//
//  CoreDataManager.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/6/26.
//


import CoreData
import Foundation

/// DB 싱크 여부 타입
enum SyncStatus: String {
    case synced = "synced"
    case pendingUpload = "pendingUpload"
    case pendingDelete = "pendingDelete"
}


/// JAENGYEO CoreDataManger
final class CoreDataManager: CoreDataManagerProtocol {
    
    // MARK: CoreData 기본 설정
    private let persistentContainer: NSPersistentContainer
    private(set) var loadError: CoreDataError?
    
    init() {
        persistentContainer = NSPersistentContainer(name: "JaengYeo")
        persistentContainer.loadPersistentStores { _, error in
            if let error {
                self.loadError = .storeLoadFailed(error)
            }
        }
    }
    
    
    // MARK: Custom 설정
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    
    enum CoreDataError: Error {
        case storeLoadFailed(Error)
        case contextSaveFailed(Error)
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
        let request = SubCategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", payload.id as CVarArg)
        let count = (try? context.count(for: request)) ?? 0
        guard count == 0 else { return }
        
        let entity = SubCategoryEntity(context: context)
        
        entity.id = payload.id
        entity.userId = payload.userId?.uuidString
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
            userId: entity.userId.flatMap { UUID(uuidString: $0) },
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

    func fetchAllSubCategories(mainCategory: String) throws -> [SubCategoryPayload] {
        let request: NSFetchRequest<SubCategoryEntity> = SubCategoryEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "mainCategory == %@ AND syncStatus != %@",
            mainCategory, SyncStatus.pendingDelete.rawValue
        )
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        
        do {
            return try context.fetch(request).map {
                SubCategoryPayload(
                    id: $0.id,
                    userId: $0.userId.flatMap { UUID(uuidString: $0) },
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
        
        entity.userId = payload.userId?.uuidString
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
        } catch {
            throw CoreDataError.loadFailed
        }
    }
    
    // MARK: SubCategory Soft Delete
    func softDeleteSubCategory(id: UUID) throws {
        let entity = try fetchSubCategoryEntity(of: id)
        entity.syncStatus = SyncStatus.pendingDelete.rawValue
        entity.updatedAt = Date()
        try removeSubCategoryFromProducts(subCategoryId: id)
    }
    
    //MARK: SubCategory Hard Delete
    func hardDeleteSubCategory(id: UUID) throws {
        let entity = try fetchSubCategoryEntity(of: id)
        context.delete(entity)
        do {
            try context.save()
        } catch {
            throw CoreDataError.contextSaveFailed(error)
        }
    }
}

//MARK: - MidCategory CRUD
extension CoreDataManager {
    // MARK: MidCategory Create
    func createMidCategory(_ payload: borrowing MidCategoryPayload) throws {
        let request = MidCategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", payload.id as CVarArg)
        let count = (try? context.count(for: request)) ?? 0
        guard count == 0 else { return }
        let entity = MidCategoryEntity(context: context)
        
        entity.id = payload.id
        entity.userId = payload.userId?.uuidString
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
            userId: entity.userId.flatMap { UUID(uuidString: $0) },
            mainCategory: entity.mainCategory,
            name: entity.name,
            iconName: entity.iconName,
            sortOrder: entity.sortOrder,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt,
            syncStatus: entity.syncStatus
        )
    }

    func fetchAllMidCategories(mainCategory: String) throws -> [MidCategoryPayload] {
        let request: NSFetchRequest<MidCategoryEntity> = MidCategoryEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "mainCategory == %@ AND syncStatus != %@",
            mainCategory, SyncStatus.pendingDelete.rawValue
        )
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        
        do {
            return try context.fetch(request).map {
                MidCategoryPayload(
                    id: $0.id,
                    userId: $0.userId.flatMap { UUID(uuidString: $0) },
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
        
        entity.userId = payload.userId?.uuidString
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
        } catch {
            throw CoreDataError.loadFailed
        }
    }
    
    // MARK: MidCategory Soft Delete
    func softDeleteMidCategory(id: UUID) throws {
        let entity = try fetchMidCategoryEntity(of: id)
        entity.syncStatus = SyncStatus.pendingDelete.rawValue
        entity.updatedAt = Date()
        try removeMidCategoryFromProducts(midCategoryId: id)
    }
    
    // MARK: MidCategory Hard Delete
    func hardDeleteMidCategory(id: UUID) throws {
        let entity = try fetchMidCategoryEntity(of: id)
        context.delete(entity)
        do {
            try context.save()
        } catch {
            throw CoreDataError.contextSaveFailed(error)
        }
    }
}



//MARK: - Product CRUD
extension CoreDataManager {
    // MARK: Product Create
    func createProduct(_ payload: borrowing ProductPayload) throws {
        
        let entity = ProductEntity(context: context)
        
        entity.id = payload.id
        entity.userId = payload.userId.uuidString
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
        entity.lowStockThreshold = payload.lowStockThreshold ?? 0
        entity.isFavorite = payload.isFavorite
        entity.createdAt = payload.createdAt
        entity.updatedAt = payload.updatedAt
        entity.syncStatus = payload.syncStatus
        entity.isLowStockNotificationEnabled = payload.isLowStockNotificationEnabled
        entity.caution = payload.caution
        entity.brand = payload.brand
        
        do {
            try context.save()
        } catch {
            throw CoreDataError.saveFailed
        }
    }
    
    func createProducts(payloads: [ProductPayload]) throws {
        payloads.forEach { payload in
            let entity = ProductEntity(context: context)
            entity.id = payload.id
            entity.userId = payload.userId.uuidString
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
            entity.lowStockThreshold = payload.lowStockThreshold ?? 0
            entity.isFavorite = payload.isFavorite
            entity.createdAt = payload.createdAt
            entity.updatedAt = payload.updatedAt
            entity.syncStatus = payload.syncStatus
            entity.isLowStockNotificationEnabled = payload.isLowStockNotificationEnabled
            entity.caution = payload.caution
            entity.brand = payload.brand
        }
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
            userId: UUID(uuidString: entity.userId) ?? UUID(),
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
            lowStockThreshold: entity.isLowStockNotificationEnabled ? entity.lowStockThreshold : nil,
            isFavorite: entity.isFavorite,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt,
            syncStatus: entity.syncStatus,
            isLowStockNotificationEnabled: entity.isLowStockNotificationEnabled,
            caution: entity.caution,
            brand: entity.brand
        )
    }
    
    func fetchAllProducts() throws -> [ProductPayload] {
        let request: NSFetchRequest<ProductEntity> = ProductEntity.fetchRequest()
        request.predicate = NSPredicate(format: "syncStatus != %@", SyncStatus.pendingDelete.rawValue)
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        
        do {
            return try context.fetch(request).map {
                ProductPayload(
                    id: $0.id,
                    userId: UUID(uuidString: $0.userId) ?? UUID(),
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
                    lowStockThreshold: $0.isLowStockNotificationEnabled ? $0.lowStockThreshold : nil,
                    isFavorite: $0.isFavorite,
                    createdAt: $0.createdAt,
                    updatedAt: $0.updatedAt,
                    syncStatus: $0.syncStatus,
                    isLowStockNotificationEnabled: $0.isLowStockNotificationEnabled,
                    caution: $0.caution,
                    brand: $0.brand
                )
            }
        } catch {
            throw CoreDataError.loadFailed
        }
    }
    
    // MARK: Product Update
    func updateProduct(_ payload: borrowing ProductPayload) throws {
        let entity = try fetchProductEntity(of: payload.id)
        
        entity.userId = payload.userId.uuidString
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
        entity.lowStockThreshold = payload.lowStockThreshold ?? 0
        entity.isFavorite = payload.isFavorite
        entity.updatedAt = payload.updatedAt
        entity.syncStatus = payload.syncStatus
        entity.isLowStockNotificationEnabled = payload.isLowStockNotificationEnabled
        entity.caution = payload.caution
        entity.brand = payload.brand
        
        do {
            if payload.quantity == 0 {
                entity.syncStatus = SyncStatus.pendingDelete.rawValue
                entity.updatedAt = Date()
            }
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
        } catch {
            throw CoreDataError.loadFailed
        }
    }
    
    // MARK: Product Soft Delete
    func softDeleteProduct(id: UUID) throws {
        let entity = try fetchProductEntity(of: id)
        entity.syncStatus = SyncStatus.pendingDelete.rawValue
        entity.updatedAt = Date()
        do {
            try context.save()
        } catch {
            throw CoreDataError.saveFailed
        }
    }
    
    //MARK: Product Hard Delete
    func hardDeleteProduct(id: UUID) throws {
        let entity = try fetchProductEntity(of: id)
        context.delete(entity)
        do {
            try context.save()
        } catch {
            throw CoreDataError.contextSaveFailed(error)
        }
    }
    
    // MARK: Product Category Reference Update
    func removeMidCategoryFromProducts(midCategoryId: UUID) throws {
        let request: NSFetchRequest<ProductEntity> = ProductEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "%K == %@ AND %K != %@",
            ProductEntity.Keys.midCategoryId,
            midCategoryId as CVarArg,
            ProductEntity.Keys.syncStatus,
            SyncStatus.pendingDelete.rawValue
        )

        do {
            let products = try context.fetch(request)
            products.forEach {
                $0.midCategoryId = nil
                $0.updatedAt = Date()
                
                if $0.syncStatus == SyncStatus.synced.rawValue {
                    $0.syncStatus = SyncStatus.pendingUpload.rawValue
                }
            }
            try context.save()
        } catch {
            throw CoreDataError.saveFailed
        }
    }

    func removeSubCategoryFromProducts(subCategoryId: UUID) throws {
        let request: NSFetchRequest<ProductEntity> = ProductEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "%K == %@ AND %K != %@",
            ProductEntity.Keys.subCategoryId,
            subCategoryId as CVarArg,
            ProductEntity.Keys.syncStatus,
            SyncStatus.pendingDelete.rawValue
        )
        
        do {
            let products = try context.fetch(request)
            products.forEach {
                $0.subCategoryId = nil
                $0.updatedAt = Date()
                
                if $0.syncStatus == SyncStatus.synced.rawValue {
                    $0.syncStatus = SyncStatus.pendingUpload.rawValue
                }
            }
            try context.save()
        } catch {
            throw CoreDataError.saveFailed
        }
    }
}


//TODO: 공통 로직이 많은데 Generic으로 합쳐보기
//MARK: - Product 동기화 관련
extension CoreDataManager {
    func fetchPendingUploadProducts() throws -> [ProductPayload] {
        try fetchProductsBySyncStatus(syncStatus: .pendingUpload)
    }
    
    func fetchPendingDeleteProducts() throws -> [ProductPayload] {
        try fetchProductsBySyncStatus(syncStatus: .pendingDelete)
    }
    
    private func fetchProductsBySyncStatus(syncStatus: SyncStatus) throws -> [ProductPayload] {
        let request: NSFetchRequest<ProductEntity> = ProductEntity.fetchRequest()
        request.predicate = NSPredicate(format: "syncStatus == %@", syncStatus.rawValue)
        do {
            return try context.fetch(request).map {
                ProductPayload(
                    id: $0.id,
                    userId: UUID(uuidString: $0.userId) ?? UUID(),
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
                    lowStockThreshold: $0.isLowStockNotificationEnabled ? $0.lowStockThreshold : nil,
                    isFavorite: $0.isFavorite,
                    createdAt: $0.createdAt,
                    updatedAt: $0.updatedAt,
                    syncStatus: $0.syncStatus,
                    isLowStockNotificationEnabled: $0.isLowStockNotificationEnabled,
                    caution: $0.caution,
                    brand: $0.brand
                )
            }
        } catch {
            throw CoreDataError.loadFailed
        }
    }
    
    func updateProductSyncStatus(id: UUID) throws {
        let entity = try fetchProductEntity(of: id)
        entity.syncStatus = SyncStatus.synced.rawValue
        do {
            try context.save()
        } catch {
            throw CoreDataError.saveFailed
        }
    }
}

//MARK: - SubCategory 동기화 관련
extension CoreDataManager {
    func fetchPendingUploadSubCategories() throws -> [SubCategoryPayload] {
        try fetchSubCategoriesBySyncStatus(syncStatus: .pendingUpload)
    }
    
    func fetchPendingDeleteSubCategories() throws -> [SubCategoryPayload] {
        try fetchSubCategoriesBySyncStatus(syncStatus: .pendingDelete)
    }
    
    private func fetchSubCategoriesBySyncStatus(syncStatus: SyncStatus) throws -> [SubCategoryPayload] {
        let request: NSFetchRequest<SubCategoryEntity> = SubCategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "syncStatus == %@", syncStatus.rawValue)
        do {
            return try context.fetch(request).map {
                SubCategoryPayload(
                    id: $0.id,
                    userId: $0.userId.flatMap { UUID(uuidString: $0) },
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

    func updateSubCategorySyncStatus(id: UUID) throws {
        let entity = try fetchSubCategoryEntity(of: id)
        entity.syncStatus = SyncStatus.synced.rawValue
        do {
            try context.save()
        } catch {
            throw CoreDataError.saveFailed
        }
    }
}

//MARK: - MidCategory 동기화 관련
extension CoreDataManager {
    func fetchPendingUploadMidCategories() throws -> [MidCategoryPayload] {
        try fetchMidCategoriesBySyncStatus(syncStatus: .pendingUpload)
    }
    
    func fetchPendingDeleteMidCategories() throws -> [MidCategoryPayload] {
        try fetchMidCategoriesBySyncStatus(syncStatus: .pendingDelete)
    }
    
    private func fetchMidCategoriesBySyncStatus(syncStatus: SyncStatus) throws -> [MidCategoryPayload] {
        let request: NSFetchRequest<MidCategoryEntity> = MidCategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "syncStatus == %@", syncStatus.rawValue)
        do {
            return try context.fetch(request).map {
                MidCategoryPayload(
                    id: $0.id,
                    userId: $0.userId.flatMap { UUID(uuidString: $0) },
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

    func updateMidCategorySyncStatus(id: UUID) throws {
        let entity = try fetchMidCategoryEntity(of: id)
        entity.syncStatus = SyncStatus.synced.rawValue
        do {
            try context.save()
        } catch {
            throw CoreDataError.saveFailed
        }
    }
}

//MARK: 메인화면용 로직
extension CoreDataManager {
    
    // 미분류 상품 fetch
    func fetchUnclassified() throws -> [ProductPayload] {
        let request = ProductEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isClassified == false AND syncStatus != %@", SyncStatus.pendingDelete.rawValue)
        do {
            return try context.fetch(request).map { toDomainProduct($0) }
        } catch {
            throw CoreDataError.loadFailed
        }
    }
    
    // 유통기한 임박 상품 fetch
    func fetchExpiryImminent(day: Int) throws -> [ProductPayload] {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        let deadLine = Calendar.current.date(byAdding: .day, value: day + 1, to: startOfToday) ?? Date()
        let request = ProductEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "expiryDate >= %@ AND expiryDate < %@ AND syncStatus != %@",
            startOfToday as NSDate, deadLine as NSDate, SyncStatus.pendingDelete.rawValue
        )
        request.sortDescriptors = [NSSortDescriptor(key: "expiryDate", ascending: true)]
        do {
            return try context.fetch(request).map { toDomainProduct($0) }
        } catch {
            throw CoreDataError.loadFailed
        }
    }
    
    // 재고 부족 상품 fetch
    func fetchLowStock() throws -> [ProductPayload] {
        let request = ProductEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "isLowStockNotificationEnabled == true AND quantity <= lowStockThreshold AND syncStatus != %@",
            SyncStatus.pendingDelete.rawValue
        )
        do {
            return try context.fetch(request).map { toDomainProduct($0) }
        } catch {
            throw CoreDataError.loadFailed
        }
    }
    
    
    // 최근 등록 상품 fetch
    func fetchRecent(limit: Int) throws -> [ProductPayload] {
        let request = ProductEntity.fetchRequest()
        request.predicate = NSPredicate(format: "syncStatus != %@", SyncStatus.pendingDelete.rawValue)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        request.fetchLimit = limit
        do {
            return try context.fetch(request).map { toDomainProduct($0) }
        } catch {
            throw CoreDataError.loadFailed
        }
    }
    
    // MainCategory 기준 fetch
    func fetchByMainCategory(mainCategory: String) throws -> [ProductPayload] {
        let request = ProductEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "mainCategory == %@ AND syncStatus != %@",
            mainCategory, SyncStatus.pendingDelete.rawValue
        )
        do {
            return try context.fetch(request).map { toDomainProduct($0) }
        } catch {
            throw CoreDataError.loadFailed
        }
    }
    
    private func toDomainProduct(_ entity: ProductEntity) -> ProductPayload {
        ProductPayload(
            id: entity.id,
            userId: UUID(uuidString: entity.userId) ?? UUID(),
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
            lowStockThreshold: entity.isLowStockNotificationEnabled ? entity.lowStockThreshold : nil,
            isFavorite: entity.isFavorite,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt,
            syncStatus: entity.syncStatus,
            isLowStockNotificationEnabled: entity.isLowStockNotificationEnabled,
            caution: entity.caution,
            brand: entity.brand
        )
    }
}

extension CoreDataManager {
    func fetchWithExpiryDate() throws -> [ProductPayload] {
        let request = ProductEntity.fetchRequest()
        request.predicate = NSPredicate(format: "expiryDate != nil AND syncStatus != %@", SyncStatus.pendingDelete.rawValue)
        
        do {
            return try context.fetch(request).map { toDomainProduct($0) }
        } catch {
            throw CoreDataError.loadFailed
        }
    }
    
    func fetchLowStockEnabled() throws -> [ProductPayload] {
        let request = ProductEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isLowStockNotificationEnabled == true AND syncStatus != %@", SyncStatus.pendingDelete.rawValue)
        do {
            return try context.fetch(request).map { toDomainProduct($0) }
        } catch {
            throw CoreDataError.loadFailed
        }
    }
}

extension CoreDataManager {
    func saveRecentSearch(keyword: String) throws {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let request = RecentSearchEntity.fetchRequest()
        request.predicate = NSPredicate(format: "keyword == %@", trimmed)
        request.fetchLimit = 1
        
        if let existing = try context.fetch(request).first {
            existing.searchedAt = Date()
        } else {
            let entity = RecentSearchEntity(context: context)
            entity.id = UUID()
            entity.keyword = trimmed
            entity.searchedAt = Date()
        }
        
        do {
            try context.save()
        } catch {
            throw CoreDataError.saveFailed
        }
        try trimRecentSearches(limit: 10)
    }
    
    func fetchRecentSearches(limit: Int) throws -> [RecentSearchPayload] {
        let request = RecentSearchEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "searchedAt", ascending: false)
        ]
        request.fetchLimit = limit
        do {
            return try context.fetch(request).map {
                RecentSearchPayload(
                    id: $0.id,
                    keyword: $0.keyword,
                    searchedAt: $0.searchedAt
                )
            }
        } catch {
            throw CoreDataError.loadFailed
        }
    }
    
    func deleteRecentSearch(id: UUID) throws {
        let request = RecentSearchEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        guard let entity = try context.fetch(request).first else { return }
        context.delete(entity)
        
        do {
            try context.save()
        } catch {
            throw CoreDataError.contextSaveFailed(error)
        }
    }
    
    func deleteAllRecentSearches() throws {
        let request = RecentSearchEntity.fetchRequest()
        do {
            let entities = try context.fetch(request)
            entities.forEach { context.delete($0) }
            try context.save()
        } catch {
            throw CoreDataError.contextSaveFailed(error)
        }
    }
    
    func deleteAllUserData() throws {
        let entityNames = [
            ProductEntity.className,
            MidCategoryEntity.className,
            SubCategoryEntity.className,
            RecentSearchEntity.className
        ]
        for name in entityNames {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: name)
            let batchDelete = NSBatchDeleteRequest(fetchRequest: request)
            batchDelete.resultType = .resultTypeObjectIDs
            let result = try context.execute(batchDelete) as? NSBatchDeleteResult
            if let objectIDs = result?.result as? [NSManagedObjectID] {
                NSManagedObjectContext.mergeChanges(
                    fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs],
                    into: [context]
                )
            }
        }
    }

    // 최대 보관 개수 초과 시 오래된 항목 삭제용 -> 내부호출용으로 protocol 추상화 x
    private func trimRecentSearches(limit: Int) throws {
        let request = RecentSearchEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "searchedAt", ascending: false)
        ]
        let all = try context.fetch(request)
        guard all.count > limit else { return }
        
        let toDelete = all[limit...]
        toDelete.forEach { context.delete($0) }
        
        try context.save()
    }
}
