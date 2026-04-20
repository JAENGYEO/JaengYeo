//
//  Constants.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/13/26.
//

import Foundation

enum Constants {
    enum Supabase {
        static let url = (Bundle.main.infoDictionary?["SUPABASE_URL"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        static let anonKey = (Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
