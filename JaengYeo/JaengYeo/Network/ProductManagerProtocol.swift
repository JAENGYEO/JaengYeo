//
//  ProductManagerProtocol.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/6/26.
//

import Foundation

protocol ProductManagerProtocol {
    
    // 전체 아이템 목록 조회 (재고현황 화면)
    func fetchAll() async throws -> [ProductDTO]
    // 미분류 아이템 조회
    func fetchUnclassified() async throws -> [ProductDTO]
    // 대분류별 아이템 조회
    func fetchByMainCategory(mainCategory: String) async throws -> [ProductDTO]
    // 유통기한 임박 아이템 조회
    func fetchExpiryDay(day: Int) async throws -> [ProductDTO]
    // 재고 임박 아이템 조회
    func fetchLowStock() async throws -> [ProductDTO]
    // 최근 등록 아이템 조회
    func fetchRecent(limit: Int) async throws -> [ProductDTO]
    // 아이템 생성
    func create(dto: ProductDTO) async throws
    // 아이템 수정
    func update(dto: ProductDTO) async throws
    // 아이템 소프트 삭제
    func softDelete(id: UUID) async throws
}
