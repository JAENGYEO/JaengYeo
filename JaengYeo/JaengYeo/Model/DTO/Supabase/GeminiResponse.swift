//
//  GeminiResponse.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/9/26.
//

import Foundation

struct GeminiResponse: Decodable {
    let items: [GeminiItem]
}

struct GeminiItem: Decodable {
    let name: String
    let estimatedCategory: String?
    let estimatedQuantity: Int?
}
