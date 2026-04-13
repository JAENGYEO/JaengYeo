//
//  CategoryMockData.swift
//  JaengYeo
//
//  Created by Codex on 4/13/26.
//

import Foundation

enum CategoryMockID {
    enum Mid {
        static let foodRefrigerator = uuid("00000000-0000-0000-0001-000000000001")
        static let foodFreezer = uuid("00000000-0000-0000-0001-000000000002")
        static let foodRoomTemperature = uuid("00000000-0000-0000-0001-000000000003")
        static let foodPantry = uuid("00000000-0000-0000-0001-000000000004")
        static let foodKitchenShelf = uuid("00000000-0000-0000-0001-000000000005")
        static let foodVeranda = uuid("00000000-0000-0000-0001-000000000006")
        static let householdBathroom = uuid("00000000-0000-0000-0002-000000000001")
        static let householdKitchen = uuid("00000000-0000-0000-0002-000000000002")
        static let householdLaundry = uuid("00000000-0000-0000-0002-000000000003")
        static let householdEntrance = uuid("00000000-0000-0000-0002-000000000004")
        static let householdStorage = uuid("00000000-0000-0000-0002-000000000005")
        static let householdWarehouse = uuid("00000000-0000-0000-0002-000000000006")
    }
    
    enum Sub {
        static let vegetable = uuid("00000000-0000-0000-0003-000000000001")
        static let meat = uuid("00000000-0000-0000-0003-000000000002")
        static let seafood = uuid("00000000-0000-0000-0003-000000000003")
        static let egg = uuid("00000000-0000-0000-0003-000000000004")
        static let dairy = uuid("00000000-0000-0000-0003-000000000005")
        static let beverage = uuid("00000000-0000-0000-0003-000000000006")
        static let alcohol = uuid("00000000-0000-0000-0003-000000000007")
        static let seasoning = uuid("00000000-0000-0000-0003-000000000008")
        static let spice = uuid("00000000-0000-0000-0003-000000000009")
        static let dessert = uuid("00000000-0000-0000-0003-000000000010")
        static let snack = uuid("00000000-0000-0000-0003-000000000011")
        static let grain = uuid("00000000-0000-0000-0003-000000000012")
        static let nut = uuid("00000000-0000-0000-0003-000000000013")
        static let detergent = uuid("00000000-0000-0000-0004-000000000001")
        static let cleaning = uuid("00000000-0000-0000-0004-000000000002")
        static let bathroom = uuid("00000000-0000-0000-0004-000000000003")
        static let kitchen = uuid("00000000-0000-0000-0004-000000000004")
        static let hygiene = uuid("00000000-0000-0000-0004-000000000005")
        static let laundry = uuid("00000000-0000-0000-0004-000000000006")
        static let storage = uuid("00000000-0000-0000-0004-000000000007")
        static let diffuser = uuid("00000000-0000-0000-0004-000000000008")
        static let stationery = uuid("00000000-0000-0000-0004-000000000009")
        static let expendable = uuid("00000000-0000-0000-0004-000000000010")
        static let tool = uuid("00000000-0000-0000-0004-000000000011")
        static let pet = uuid("00000000-0000-0000-0004-000000000012")
    }
}

//MARK: - Method
private extension CategoryMockID {
    /// UUID 변환
    static func uuid(_ value: String) -> UUID {
        UUID(uuidString: value) ?? UUID()
    }
}

private enum CategoryMockSeed {
    static let userDefaultsKey = "hasSeededMockCategories"
    
    static var midCategoryPayloads: [MidCategoryPayload] {
        makeMidCategoryPayloads(
            mainCategory: "식재료",
            items: [
                ("냉장고", CategoryMockID.Mid.foodRefrigerator),
                ("냉동실", CategoryMockID.Mid.foodFreezer),
                ("실온", CategoryMockID.Mid.foodRoomTemperature),
                ("팬트리", CategoryMockID.Mid.foodPantry),
                ("주방 선반", CategoryMockID.Mid.foodKitchenShelf),
                ("베란다", CategoryMockID.Mid.foodVeranda)
            ]
        ) + makeMidCategoryPayloads(
            mainCategory: "생활용품",
            items: [
                ("욕실", CategoryMockID.Mid.householdBathroom),
                ("주방", CategoryMockID.Mid.householdKitchen),
                ("세탁실", CategoryMockID.Mid.householdLaundry),
                ("현관", CategoryMockID.Mid.householdEntrance),
                ("수납장", CategoryMockID.Mid.householdStorage),
                ("창고", CategoryMockID.Mid.householdWarehouse)
            ]
        )
    }
    
    static var subCategoryPayloads: [SubCategoryPayload] {
        makeSubCategoryPayloads(
            mainCategory: "식재료",
            items: [
                ("채소", CategoryMockID.Sub.vegetable),
                ("육류", CategoryMockID.Sub.meat),
                ("해산물", CategoryMockID.Sub.seafood),
                ("난류", CategoryMockID.Sub.egg),
                ("유제품", CategoryMockID.Sub.dairy),
                ("음료", CategoryMockID.Sub.beverage),
                ("주류", CategoryMockID.Sub.alcohol),
                ("조미료", CategoryMockID.Sub.seasoning),
                ("향신료", CategoryMockID.Sub.spice),
                ("디저트", CategoryMockID.Sub.dessert),
                ("과자", CategoryMockID.Sub.snack),
                ("곡류", CategoryMockID.Sub.grain),
                ("견과류", CategoryMockID.Sub.nut)
            ]
        ) + makeSubCategoryPayloads(
            mainCategory: "생활용품",
            items: [
                ("세제", CategoryMockID.Sub.detergent),
                ("청소용품", CategoryMockID.Sub.cleaning),
                ("욕실용품", CategoryMockID.Sub.bathroom),
                ("주방용품", CategoryMockID.Sub.kitchen),
                ("위생용품", CategoryMockID.Sub.hygiene),
                ("세탁용품", CategoryMockID.Sub.laundry),
                ("수납용품", CategoryMockID.Sub.storage),
                ("방향제", CategoryMockID.Sub.diffuser),
                ("문구", CategoryMockID.Sub.stationery),
                ("소모품", CategoryMockID.Sub.expendable),
                ("공구", CategoryMockID.Sub.tool),
                ("반려용품", CategoryMockID.Sub.pet)
            ]
        )
    }
}

//MARK: - Method
private extension CategoryMockSeed {
    /// 중분류 목업 생성
    static func makeMidCategoryPayloads(
        mainCategory: String,
        items: [(name: String, id: UUID)]
    ) -> [MidCategoryPayload] {
        let now = Date()
        
        return items.enumerated().map { index, item in
            MidCategoryPayload(
                id: item.id,
                userId: "mock-user",
                mainCategory: mainCategory,
                name: item.name,
                iconName: "Category",
                sortOrder: Int32(index),
                createdAt: now,
                updatedAt: now,
                syncStatus: SyncStatus.synced.rawValue
            )
        }
    }
    
    /// 소분류 목업 생성
    static func makeSubCategoryPayloads(
        mainCategory: String,
        items: [(name: String, id: UUID)]
    ) -> [SubCategoryPayload] {
        let now = Date()
        
        return items.enumerated().map { index, item in
            SubCategoryPayload(
                id: item.id,
                userId: "mock-user",
                mainCategory: mainCategory,
                name: item.name,
                iconName: "Category",
                thumbnailKey: nil,
                sortOrder: Int32(index),
                createdAt: now,
                updatedAt: now,
                syncStatus: SyncStatus.synced.rawValue
            )
        }
    }
}

extension CoreDataManager {
    /// 목업 카테고리 데이터 주입
    func seedMockCategoriesIfNeeded() throws {
        if UserDefaults.standard.bool(forKey: CategoryMockSeed.userDefaultsKey) {
            return
        }
        
        let hasMidCategories = try fetchAllMidCategories(mainCategory: "식재료").isEmpty == false ||
            fetchAllMidCategories(mainCategory: "생활용품").isEmpty == false
        let hasSubCategories = try fetchAllSubCategories(mainCategory: "식재료").isEmpty == false ||
            fetchAllSubCategories(mainCategory: "생활용품").isEmpty == false
        
        if hasMidCategories || hasSubCategories {
            UserDefaults.standard.set(true, forKey: CategoryMockSeed.userDefaultsKey)
            return
        }
        
        try CategoryMockSeed.midCategoryPayloads.forEach { payload in
            try createMidCategory(payload)
        }
        
        try CategoryMockSeed.subCategoryPayloads.forEach { payload in
            try createSubCategory(payload)
        }
        
        UserDefaults.standard.set(true, forKey: CategoryMockSeed.userDefaultsKey)
    }
}
