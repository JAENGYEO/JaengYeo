//
//  CameraMode.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/8/26.
//

import Foundation

enum CameraMode {
    case barcode // 바코드
    case receipt // 영수증
    case aiVision // Gemini 연결
    case manual // 직접 입력 -> RegisterFormViewController로 연결
}
