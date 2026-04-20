//
//  NotificationManager.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/16/26.
//

import Foundation
import os
import RxSwift
import RxCocoa
import Supabase

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    private var client: SupabaseClient?
    
    private let disposeBag = DisposeBag()
    let notificationTapped = PublishSubject<ItemListType>()
    
    private var pendingTokenData: Data?
    
    func config(client: SupabaseClient) {
        self.client = client
        if let tokenData = pendingTokenData {
            syncDeviceToken(tokenData: tokenData)
            pendingTokenData = nil
        }
    }
    
    func syncDeviceToken(tokenData: Data) {
        guard let client else {
            pendingTokenData = tokenData
            return
        }
        let token = tokenData.map { String(format: "%02x", $0) }.joined()
        
        Task {
            guard let accessToken = try? await client.auth.session.accessToken else { return }
            guard let url = URL(string: "\(Constants.Supabase.url)/functions/v1/sync-device-token") else {
                Logger().error("NotificationManager: 잘못된 URL")
                return
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            
            let body: [String: String] = ["deviceToken": token]
            request.httpBody = try? JSONEncoder().encode(body)
            
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    Logger().info("Notification: 응답 코드 - \(httpResponse.statusCode)")
                }
            } catch {
                Logger().error("Notification: 요청 실패 - \(error.localizedDescription)")
            }
        }
    }
    
    func handleNotificationTapped(userInfo: [AnyHashable: Any]) {
        guard let type = userInfo["type"] as? String else { return }
        if type == "expiryImminent" {
            notificationTapped.onNext(.expiryImminent(day: 1))
        } else if type == "lowStock" {
            notificationTapped.onNext(.lowStock)
        }
    }
}
