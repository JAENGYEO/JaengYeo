//
//  ReceiptProtocol.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/14/26.
//

import Foundation
import UIKit

protocol ReceiptProtocol {
    // OCR 분석
    func analyzeReceipt(image: UIImage) async throws -> [RegisterFormData]
    // 데이터 파싱
    func parseReceipt(text: String) async throws -> [RegisterFormData]
}
