//
//  AuthManagerProtocol.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/20/26.
//

import Foundation

protocol AuthManagerProtocol {
    var currentUserId: UUID? { get }
    func clearSessionIfReinstalled() async
    func restoreSession() async -> Bool
    func signInWithApple(idToken: String, nonce: String) async throws
    func signOut() async throws
}
