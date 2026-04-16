//
//  Constants.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/13/26.
//

import Foundation

enum Constants {
    enum Dev {
        static let userId = UUID(uuidString: "9b6fb054-73e5-478a-9b84-0ad49ff984bb")! // 로그인 기능 구현 시 수정 필요
    }
    enum Supabase {
        static let url = (Bundle.main.infoDictionary?["SUPABASE_URL"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        static let anonKey = (Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
