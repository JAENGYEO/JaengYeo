//
//  DeepLink.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/28/26.
//

import Foundation

enum DeepLink {
    
    enum Scheme {
        static let main = "jaengyeo"
    }
    
    enum Host {
        static let product = "product"
        static let list = "list"
        static let camera = "camera"
        static let widgetSettings = "widget-settings"
        static let cart = "cart"
    }
    
    enum Path {
        static let confirmDelete = "confirm-delete"
        static let lowStock = "lowStock"
        static let expiry = "expiry"
    }
    
    enum Query {
        static let mode = "mode"
    }
    
    // 상품 상세 진입
    // jaengyeo://product/{uuid}
    case product(id: UUID)
    // 상품 마지막 1개 차감 알럿 트리거
    // jaengyeo://product/{uuid}/confirm-delete
    case confirmDelete(id: UUID)
    // 재고 부족 목록
    // jaengyeo://list/lowStock
    case lowStockList
    // 유통기한 임박 목록
    // jaengyeo://list/expiry
    case expiryList
    // 카메라 모드 진입
    // jaengyeo://camera?mode={mode}
    case camera(mode: CameraMode)
    // 위젯 설정 화면
    // jaengyeo://widget-settings
    case widgetSettings
    // 장바구니 화면
    // jaengyeo://cart
    case cart
    
    //URL을 DeepLink case로 변환
    init?(url: URL) {
        guard url.scheme == Scheme.main else { return nil }
        
        let host = url.host
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        
        switch host {
        case Host.product:
            guard let idString = pathComponents.first,
                  let id = UUID(uuidString: idString) else { return nil }
            
            if pathComponents.count == 1 {
                self = .product(id: id)
            } else if pathComponents.count == 2, pathComponents[1] == Path.confirmDelete {
                self = .confirmDelete(id: id)
            } else {
                return nil
            }
            
        case Host.list:
            guard let listType = pathComponents.first else { return nil }
            switch listType {
            case Path.lowStock: self = .lowStockList
            case Path.expiry: self = .expiryList
            default: return nil
            }
            
        case Host.camera:
            let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
            let modeString = queryItems?.first(where: { $0.name == Query.mode })?.value ?? CameraMode.manual.rawValue
            guard let mode = CameraMode(rawValue: modeString) else { return nil }
            self = .camera(mode: mode)
            
        case Host.widgetSettings:
            self = .widgetSettings
            
        case Host.cart:
            self = .cart
            
        default:
            return nil
        }
    }
}
