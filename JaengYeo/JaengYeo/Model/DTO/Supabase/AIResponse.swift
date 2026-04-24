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

    enum CodingKeys: String, CodingKey {
        case name, estimatedCategory, estimatedQuantity
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        estimatedCategory = try container.decodeIfPresent(String.self, forKey: .estimatedCategory)

        if let intValue = try? container.decodeIfPresent(Int.self, forKey: .estimatedQuantity) {
            estimatedQuantity = intValue
        } else if let strValue = try? container.decodeIfPresent(String.self, forKey: .estimatedQuantity) {
            estimatedQuantity = Int(strValue.filter { $0.isNumber })
        } else {
            estimatedQuantity = nil
        }
    }
}
