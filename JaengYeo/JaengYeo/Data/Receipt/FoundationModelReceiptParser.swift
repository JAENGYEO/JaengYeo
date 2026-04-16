//
//  FoundationModelReceiptParser.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/14/26.
//

import UIKit
import FoundationModels

@available(iOS 26, *)
final class FoundationModelReceiptParser: ReceiptProtocol {
    
    @Generable
    struct ReceiptOutput {
        var items: [ReceiptItem]
    }
    
    @Generable
    struct ReceiptItem {
        @Guide(description: "상품명")
        var name: String
        @Guide(description: "카테고리: 식재료/생활용품")
        var estimatedCategory: String
        @Guide(description: "수량")
        var estimatedQuantity: Int
    }
    
    //직접 호출 XX
    func analyzeReceipt(image: UIImage) async throws -> [RegisterFormData] {
        throw NSError(domain: "FoundationModelReceiptParser", code: -1, userInfo: [NSLocalizedDescriptionKey: "이미지 분석은 지원하지 않습니다."])
    }
    
    func parseReceipt(text: String) async throws -> [RegisterFormData] {
        let session = LanguageModelSession()
        let prompt = """
            아래 텍스트가 영수증이 아니거나 상품 목록을 추출할 수 없으면 빈 배열을 반환해줘.
            영수증인 경우에만 구매한 상품 목록을 추출해줘.
            
            \(text)
            """
        let output = try await session.respond(
            to: prompt,
            generating: ReceiptOutput.self
        )
        return output.content.items.map { item in
            var form = RegisterFormData()
            form.name = item.name
            form.mainCategory = item.estimatedCategory
            form.quantity = item.estimatedQuantity
            return form
        }
    }
    
    
    
    
}
