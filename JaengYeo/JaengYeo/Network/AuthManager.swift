//
//  AuthManager.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/20/26.
//

import Foundation
import Supabase

final class AuthManager: AuthManagerProtocol {
    
    private let client: SupabaseClient
    
    init(client: SupabaseClient) {
        self.client = client
    }
    
    var currentUserId: UUID? {
        client.auth.currentSession?.user.id
    }
    
    func clearSessionIfReinstalled() async {
        let key = "hasLaunchedBefore"
        if !UserDefaults.standard.bool(forKey: key) {
            try? await client.auth.signOut()
            UserDefaults.standard.set(true, forKey: key)
        }
    }
    
    func restoreSession() async -> Bool {
        do {
            _ = try await client.auth.session
            return currentUserId != nil
        } catch {
            return false
        }
    }
    
    func signInWithApple(idToken: String, nonce: String) async throws {
        try await client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce))
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    func deleteAccount() async throws {
        let accessToken = try await client.auth.session.accessToken
        
        guard let url = URL(string: "\(Constants.Supabase.url)/functions/v1/delete-account") else {
            throw NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "잘못된 URL"])
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "계정 삭제 실패"])
        }
        try await client.auth.signOut()
    }
    
}
