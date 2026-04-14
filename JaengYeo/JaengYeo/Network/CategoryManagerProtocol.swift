//
//  CategoryManagerProtocol.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/6/26.
//

import Foundation

protocol CategoryManagerProtocol {
    
    // 중분류 목록 조회
    func fetchMidCategory(mainCategory: String) async throws -> [MidCategoryDTO]
    // 소분류 목록 조회
    func fetchSubCategory(mainCategory: String) async throws -> [SubCategoryDTO]
    // 중분류 생성
    func createMidCategory(dto: MidCategoryDTO) async throws
    // 소분류 생성
    func createSubCategory(dto: SubCategoryDTO) async throws
    // 중분류 소프트 삭제
    func softDeleteMidCategory(id: UUID) async throws
    // 소분류 소프트 삭제
    func softDeleteSubCategory(id: UUID) async throws
    // 중분류 upsert
    func upsertMidCategory(dto: MidCategoryDTO) async throws
    // 소분류 upsert
    func upsertSubCategory(dto: SubCategoryDTO) async throws
    // 기본 MidCategory Fetch
    func fetchSystemMidCategories(mainCategory: String) async throws -> [MidCategoryDTO]
    // 기본 SubCategory Fetch
    func fetchSystemSubCategories(mainCategory: String) async throws -> [SubCategoryDTO]
}
