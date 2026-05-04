//
//  RegisterOptionField.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/13/26.
//

import Foundation

enum RegisterOptionField: CaseIterable,Hashable {
    case subCategory, photo, expiryDate, caution, brand, stockAlert, memo

    var title: String {
        switch self {
        case .subCategory:
            return "종류"
        case .photo:
            return "사진"
        case .expiryDate:
            return "유통기한"
        case .caution:
            return "유의사항 / 취급 주의사항"
        case .brand:
            return "브랜드"
        case .stockAlert:
            return "알림 재고 수량 설정"
        case .memo:
            return "메모"
        }
    }
}
