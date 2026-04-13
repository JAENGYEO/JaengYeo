//
//  AIResponse.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/9/26.
//

import Foundation

struct AIResponse: Decodable {
    let items: [AIResponseItem]
}

struct AIResponseItem: Decodable {
    let name: String
    let estimatedCategory: String?
    let estimatedQuantity: Int?
}
