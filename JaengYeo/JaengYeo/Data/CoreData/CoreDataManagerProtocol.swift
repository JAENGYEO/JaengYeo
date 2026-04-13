//
//  CoreDataManagerProtocol.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/7/26.
//

import CoreData
import Foundation

protocol CoreDataManagerProtocol {
    
    var context: NSManagedObjectContext { get }
    
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
    
    
    //MARK: - 메인화면 조회용
    func fetchUnclassified() throws -> [ProductPayload]
    func fetchExpiryImminent(day: Int) throws -> [ProductPayload]
    func fetchLowStock() throws -> [ProductPayload]
    func fetchRecent(limit: Int) throws -> [ProductPayload]
    func fetchByMainCategory(mainCategory: String) throws -> [ProductPayload]
}
