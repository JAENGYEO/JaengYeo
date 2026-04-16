//
//  ReceiptAnalyzer.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/14/26.
//

import UIKit

final class ReceiptAnalyzer: ReceiptProtocol {
    private let ocrService: ReceiptOCRService
    
    private let parser: ReceiptProtocol
    
    init(parser: ReceiptProtocol) {
        self.ocrService = ReceiptOCRService()
        self.parser = parser
    }
    
    // 이미지 -> OCR -> 파싱 파이프라인 구축
    func analyzeReceipt(image: UIImage) async throws -> [RegisterFormData] {
        let ocrText = try await ocrService.recognizeText(image: image)
        guard !ocrText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
        return try await parser.parseReceipt(text: ocrText)
    }
    
    func parseReceipt(text: String) async throws -> [RegisterFormData] {
        return try await parser.parseReceipt(text: text)
    }
}
