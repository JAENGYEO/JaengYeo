//
//  CategoryManager.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/6/26.
//

import Foundation
import Supabase

private enum Table: String {
    case midCategory = "mid_categories"
    case subCategory = "sub_categories"
}

private enum Column: String {
    case id
    case userId = "user_id"
    case mainCategory = "main_category"
    case sortOrder = "sort_order"
    case deletedAt = "deleted_at"
}

final class CategoryManager: CategoryManagerProtocol {
    
    private let client: SupabaseClient
    
    init(client: SupabaseClient) {
        self.client = client
    }
    
    func fetchMidCategory(mainCategory: String) async throws -> [MidCategoryDTO] {
        try await client
            .from(Table.midCategory.rawValue)
            .select()
            .eq(Column.mainCategory.rawValue, value: mainCategory)
            .or("\(Column.userId.rawValue).is.null,\(Column.userId.rawValue).eq.\(Constants.Dev.userId)") // postgREST 필터 문법 사용
            .order(Column.sortOrder.rawValue, ascending: true)
            .execute()
            .value
    }
    
    func fetchSubCategory(mainCategory: String) async throws -> [SubCategoryDTO] {
        try await client
            .from(Table.subCategory.rawValue)
            .select()
            .eq(Column.mainCategory.rawValue, value: mainCategory)
            .or("\(Column.userId.rawValue).is.null,\(Column.userId.rawValue).eq.\(Constants.Dev.userId)")
            .order(Column.sortOrder.rawValue, ascending: true)
            .execute()
            .value
    }
    
    func createMidCategory(dto: MidCategoryDTO) async throws {
        try await client
            .from(Table.midCategory.rawValue)
            .insert(dto)
            .execute()
    }
    
    func createSubCategory(dto: SubCategoryDTO) async throws {
        try await client
            .from(Table.subCategory.rawValue)
            .insert(dto)
            .execute()
    }
    
    func softDeleteMidCategory(id: UUID) async throws {
        try await client
            .from(Table.midCategory.rawValue)
            .update([Column.deletedAt.rawValue: Date().ISO8601Format()])
            .eq(Column.id.rawValue, value: id)
            .execute()
    }
    
    func softDeleteSubCategory(id: UUID) async throws {
        try await client
            .from(Table.subCategory.rawValue)
            .update([Column.deletedAt.rawValue: Date().ISO8601Format()])
            .eq(Column.id.rawValue, value: id)
            .execute()
    }
    
    func upsertMidCategory(dto: MidCategoryDTO) async throws {
        try await client
            .from(Table.midCategory.rawValue)
            .upsert(dto)
            .execute()
    }
    
    func upsertSubCategory(dto: SubCategoryDTO) async throws {
        try await client
            .from(Table.subCategory.rawValue)
            .upsert(dto)
            .execute()
    }
}
