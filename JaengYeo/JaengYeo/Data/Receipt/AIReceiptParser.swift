//
//  AIReceiptParser.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/14/26.
//

import UIKit
import Supabase

final class AIReceiptParser: ReceiptProtocol {
    private let client: SupabaseClient
    
    init(client: SupabaseClient) {
        self.client = client
    }
    
    // 이미지 분석 XX
    func analyzeReceipt(image: UIImage) async throws -> [RegisterFormData] {
        throw NSError(domain: "AIReceiptParser", code: -1, userInfo: [NSLocalizedDescriptionKey: "이미지 분석은 지원하지 않습니다."])
    }
    
    // 파싱만 담당
    func parseReceipt(text: String) async throws -> [RegisterFormData] {
        let body: [String: AnyJSON] = [
            "mode": "receipt",
            "ocrText": AnyJSON(stringLiteral: text)
        ]
        let response: AIResponse = try await client.functions
            .invoke("gpt-vision", options: FunctionInvokeOptions(body: body))
        return response.items.map { item in
            var form = RegisterFormData()
            form.name = item.name
            form.mainCategory = item.estimatedCategory
            form.quantity = item.estimatedQuantity
            return form
        }
    }
}
