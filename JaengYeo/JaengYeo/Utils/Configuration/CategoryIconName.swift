//
//  CategoryIconName.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/15/26.
//

import Foundation

/// 식재료 중분류 아이콘
enum FoodMidCategoryIcon: String, CaseIterable {
    case defaultIcon = "categoryIcon"
}

/// 식재료 소분류 아이콘
enum FoodSubCategoryIcon: String, CaseIterable {
    case defaultIcon = "categoryIcon"
}

/// 생활용품 중분류 아이콘
enum HouseholdMidCategoryIcon: String, CaseIterable {
    case defaultIcon = "categoryIcon"
}

/// 생활용품 소분류 아이콘
enum HouseholdSubCategoryIcon: String, CaseIterable {
    case defaultIcon = "categoryIcon"
}

//MARK: - Method
extension CaseIterable where Self: RawRepresentable, RawValue == String {
    /// 아이콘 이름 목록
    static var iconNames: [String] {
        allCases.map { $0.rawValue }
    }
}
