//
//  ReceiptOCRService.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/14/26.
//

import Vision
import UIKit

final class ReceiptOCRService {
    func recognizeText(image: UIImage) async throws -> String {
        
        // UIImage -> CGImage 변환
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "ReceiptOCR", code: -1, userInfo: [NSLocalizedDescriptionKey: "이미지 변환 실패"])
        }
        // Vision 콜백 기반 API -> async/await 변경
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let text = (request.results as? [VNRecognizedTextObservation])?
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n") ?? ""
                // 텍스트 반환 후 continuation 종료
                continuation.resume(returning: text)
            }
            request.recognitionLanguages = ["ko-KR", "en-US"]
            // 속도보다 정확도 우선: .accurate
            request.recognitionLevel = .accurate
            
            let handler = VNImageRequestHandler(cgImage: cgImage)
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
