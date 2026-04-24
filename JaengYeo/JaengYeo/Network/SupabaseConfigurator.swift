//
//  SupabaseConfigurator.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/6/26.
//

import Foundation
import Supabase

func makeSupabaseClient() -> SupabaseClient {
    guard let urlString = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String,
          let url = URL(string: urlString),
          let key = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String else {
        fatalError("Supabase URL 또는 Key가 Info.plist에 설정되지 않았습니다.")
    }
    
    return SupabaseClient(
        supabaseURL: url,
        supabaseKey: key,
        options: SupabaseClientOptions(
            auth: SupabaseClientOptions.AuthOptions(
                emitLocalSessionAsInitialSession: true 
            )
        )
    )
}
