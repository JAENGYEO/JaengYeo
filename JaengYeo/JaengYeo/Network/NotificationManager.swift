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

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    private let disposeBag = DisposeBag()
    let notificationTapped = PublishSubject<ItemListType>()
    
    func syncDeviceToken(tokenData: Data) {
        let token = tokenData.map { String(format: "%02x", $0) }.joined()

        guard let url = URL(string: "\(Constants.Supabase.url)/functions/v1/sync-device-token") else {
            Logger().error("NotificationManager: 잘못된 URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(Constants.Supabase.anonKey)", forHTTPHeaderField: "Authorization")

        let body: [String: String] = [
            "userId": Constants.Dev.userId.uuidString,
            "deviceToken": token
        ]
        request.httpBody = try? JSONEncoder().encode(body)

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error {
                Logger().error("NotificationManager: 요청 실패 - \(error.localizedDescription)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                Logger().info("NotificationManager: 응답 코드 - \(httpResponse.statusCode)")
            }
        }.resume()
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
