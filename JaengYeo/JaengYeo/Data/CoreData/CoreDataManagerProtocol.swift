//
//  CoreDataManagerProtocol.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/7/26.
//

import CoreData
import Foundation
import RxSwift

protocol CoreDataManagerProtocol {
    
    //MARK: - Product
    func createProduct(_ payload: ProductPayload) throws
    func fetchProduct(of id: UUID) throws -> ProductPayload
    func fetchAllProducts() throws -> [ProductPayload]
    func updateProduct(_ payload: ProductPayload) throws
    func fetchPendingUploadProducts() throws -> [ProductPayload]
    func fetchPendingDeleteProducts() throws -> [ProductPayload]
    func updateProductSyncStatus(id: UUID) throws
    func softDeleteProduct(id: UUID) throws
    func hardDeleteProduct(id: UUID) throws
    func createProducts(payloads: [ProductPayload]) throws
    func removeMidCategoryFromProducts(midCategoryId: UUID) throws
    func removeSubCategoryFromProducts(subCategoryId: UUID) throws
    func observeProducts(
        predicate: NSPredicate?,
        sortDescriptors: [NSSortDescriptor]
    ) -> Observable<[ProductEntity]>
    
    //MARK: - SubCategory
    func createSubCategory(_ payload: SubCategoryPayload) throws
    func fetchSubCategory(of id: UUID) throws -> SubCategoryPayload
    func fetchAllSubCategories(mainCategory: String) throws -> [SubCategoryPayload]
    func updateSubCategory(_ payload: SubCategoryPayload) throws
    func fetchPendingUploadSubCategories() throws -> [SubCategoryPayload]
    func fetchPendingDeleteSubCategories() throws -> [SubCategoryPayload]
    func updateSubCategorySyncStatus(id: UUID) throws
    func softDeleteSubCategory(id: UUID) throws
    func hardDeleteSubCategory(id: UUID) throws
    func observeSubCategories(
        predicate: NSPredicate?,
        sortDescriptors: [NSSortDescriptor]
    ) -> Observable<[SubCategoryEntity]>
    
    //MARK: - MidCategory
    func createMidCategory(_ payload: MidCategoryPayload) throws
    func fetchMidCategory(of id: UUID) throws -> MidCategoryPayload
    func fetchAllMidCategories(mainCategory: String) throws -> [MidCategoryPayload]
    func updateMidCategory(_ payload: MidCategoryPayload) throws
    func fetchPendingUploadMidCategories() throws -> [MidCategoryPayload]
    func fetchPendingDeleteMidCategories() throws -> [MidCategoryPayload]
    func updateMidCategorySyncStatus(id: UUID) throws
    func softDeleteMidCategory(id: UUID) throws
    func hardDeleteMidCategory(id: UUID) throws
    func observeMidCategories(
        predicate: NSPredicate?,
        sortDescriptors: [NSSortDescriptor]
    ) -> Observable<[MidCategoryEntity]>
    
    
    //MARK: - 메인화면 조회용
    func fetchUnclassified() throws -> [ProductPayload]
    func fetchExpiryImminent(day: Int) throws -> [ProductPayload]
    func fetchLowStock() throws -> [ProductPayload]
    func fetchRecent(limit: Int) throws -> [ProductPayload]
    func fetchByMainCategory(mainCategory: String) throws -> [ProductPayload]
    func fetchWithExpiryDate() throws -> [ProductPayload]
    func fetchLowStockEnabled() throws -> [ProductPayload]
    
    //MARK: - 최근검색어
    func saveRecentSearch(keyword: String) throws
    func fetchRecentSearches(limit: Int) throws -> [RecentSearchPayload]
    func deleteRecentSearch(id: UUID) throws
    func deleteAllRecentSearches() throws
    
    //MARK: - 계정 삭제
    func deleteAllUserData() throws
    
    //MARK: - 위젯 프리셋
    func createWidgetPreset(payload: WidgetPresetPayload) throws
    func fetchAllWidgetPresets() throws -> [WidgetPresetPayload]
    func fetchWidgetPreset(id: UUID) throws -> WidgetPresetPayload?
    func updateWidgetPreset(payload: WidgetPresetPayload) throws
    func deleteWidgetPreset(id: UUID) throws

    //MARK: - 장바구니
    func createCartItem(_ payload: CartItemPayload) throws
    func fetchAllCartItems() throws -> [CartItemPayload]
    func fetchCartItem(of id: UUID) throws -> CartItemPayload
    func updateCartItem(_ payload: CartItemPayload) throws
    func deleteCartItem(id: UUID) throws
    func observeCartItems(
        sortDescriptors: [NSSortDescriptor]
    ) -> Observable<[CartItemEntity]>
}
