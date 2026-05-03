//
//  CartItemPayload.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/28/26.
//

import Foundation

/// 장바구니 데이터 Payload 구조체
struct CartItemPayload {
    let id: UUID
    let referenceId: UUID?
    let name: String
    let mainCategory: String
    let quantity: Int
    let createdAt: Date
}

//MARK: - Method
extension CartItemPayload {
    // CartItemPayload -> CartItem 변환 메소드
    func toDomain() -> CartItem {
        CartItem(
            id: id,
            referenceId: referenceId,
            name: name,
            mainCategory: mainCategory,
            quantity: quantity,
            createdAt: createdAt
        )
    }
}

extension CartItem {
    var toPayload: CartItemPayload {
        CartItemPayload(
            id: id,
            referenceId: referenceId,
            name: name,
            mainCategory: mainCategory,
            quantity: quantity,
            createdAt: createdAt ?? Date()
        )
    }
}
