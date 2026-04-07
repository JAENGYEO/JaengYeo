//
//  CoreDataManagerProtocol.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/7/26.
//

import Foundation

protocol CoreDataManagerProtocol {
    
    //MARK: - Product
    func createProduct(_ payload: ProductPayload) throws
    func fetchProduct(of id: UUID) throws -> ProductPayload
    func fetchAllProducts() throws -> [ProductPayload]
    func updateProduct(_ payload: ProductPayload) throws
    func fetchPendingUploadProducts() throws -> [ProductPayload]
    func fetchPendingDeleteProducts() throws -> [ProductPayload]
    func updateProductSyncStatus(id: UUID) throws
    func deleteProduct(id: UUID) throws
    
    //MARK: - SubCategory
    func createSubCategory(_ payload: SubCategoryPayload) throws
    func fetchSubCategory(of id: UUID) throws -> SubCategoryPayload
    func fetchAllSubCategories(mainCategory: String) throws -> [SubCategoryPayload]
    func updateSubCategory(_ payload: SubCategoryPayload) throws
    func fetchPendingUploadSubCategories() throws -> [SubCategoryPayload]
    func fetchPendingDeleteSubCategories() throws -> [SubCategoryPayload]
    func updateSubCategorySyncStatus(id: UUID) throws
    func deleteSubCategory(id: UUID) throws
    
    //MARK: - MidCategory
    func createMidCategory(_ payload: MidCategoryPayload) throws
    func fetchMidCategory(of id: UUID) throws -> MidCategoryPayload
    func fetchAllMidCategories(mainCategory: String) throws -> [MidCategoryPayload]
    func updateMidCategory(_ payload: MidCategoryPayload) throws
    func fetchPendingUploadMidCategories() throws -> [MidCategoryPayload]
    func fetchPendingDeleteMidCategories() throws -> [MidCategoryPayload]
    func updateMidCategorySyncStatus(id: UUID) throws
    func deleteMidCategory(id: UUID) throws
    
}
