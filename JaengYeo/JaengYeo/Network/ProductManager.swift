//
//  ProductManager.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/6/26.
//

import Foundation
import Supabase

private enum Table: String {
    case items
}

private enum Column: String {
      case id
      case mainCategory = "main_category"
      case expiryDate = "expiry_date"
      case isClassified = "is_classified"
      case isLowStockNotificationEnabled = "is_low_stock_notification_enabled"
      case createdAt = "created_at"
      case deletedAt = "deleted_at"
  }

final class ProductManager: ProductManagerProtocol {
    
    private let client: SupabaseClient
    
    init(client: SupabaseClient) {
        self.client = client
    }
    
    func fetchAll() async throws -> [ProductDTO] {
        try await client
            .from(Table.items.rawValue) // 테이블 지정
            .select() // 조회
            .is(Column.deletedAt.rawValue, value: nil) // nil과 비교 WHERE A is NULL
            .execute() // 실행
            .value // Codable 타입으로 디코딩
    }
    
    func fetchUnclassified() async throws -> [ProductDTO] {
        try await client
            .from(Table.items.rawValue)
            .select()
            .eq(Column.isClassified.rawValue, value: false) // 동등 조건 WHERE A = B
            .is(Column.deletedAt.rawValue, value: nil)
            .execute()
            .value
    }
    
    func fetchByMainCategory(mainCategory: String) async throws -> [ProductDTO] {
        try await client
            .from(Table.items.rawValue)
            .select()
            .eq(Column.mainCategory.rawValue, value: mainCategory)
            .is(Column.deletedAt.rawValue, value: nil)
            .execute()
            .value
    }
    
    func fetchExpiryDay(day: Int) async throws -> [ProductDTO] {
        
        guard let deadLine = Calendar.current.date(byAdding: .day, value: day, to: Date()) else { return [] }
        return try await client
            .from(Table.items.rawValue)
            .select()
            .lte(Column.expiryDate.rawValue, value: deadLine.ISO8601Format()) // 이하 조건 WHERE A <= B
            .gte(Column.expiryDate.rawValue, value: Date().ISO8601Format()) // 이상 조건
            .is(Column.deletedAt.rawValue, value: nil)
            .order(Column.expiryDate.rawValue,ascending: true) // 정렬
            .execute()
            .value
    }
    
    func fetchLowStock() async throws -> [ProductDTO] {
        try await client
            .from(Table.items.rawValue)
            .select()
            .eq(Column.isLowStockNotificationEnabled.rawValue, value: true)
            .is(Column.deletedAt.rawValue, value: nil)
            .execute()
            .value
    }
    
    func fetchRecent(limit: Int) async throws -> [ProductDTO] {
        try await client
            .from(Table.items.rawValue)
            .select()
            .is(Column.deletedAt.rawValue, value: nil)
            .order(Column.createdAt.rawValue, ascending: false)
            .limit(limit) // 개수 제한
            .execute()
            .value
    }
    
    func create(dto: ProductDTO) async throws {
        try await client
            .from(Table.items.rawValue)
            .insert(dto) // 삽입
            .execute()
    }
    
    func update(dto: ProductDTO) async throws {
        try await client
            .from(Table.items.rawValue)
            .update(dto) // 수정
            .eq(Column.id.rawValue, value: dto.id)
            .execute()
    }
    
    func softDeleteProduct(id: UUID) async throws {
        try await client
            .from(Table.items.rawValue)
            .update([Column.deletedAt.rawValue: Date().ISO8601Format()])
            .eq(Column.id.rawValue, value: id)
            .execute()
    }
    
    
}
