//
//  MyPagePermissionViewModel.swift
//  JaengYeo
//
//  Created by Codex on 4/20/26.
//

import AVFoundation
import Foundation
import RxRelay
import RxSwift
import UIKit
import UserNotifications

/// 마이페이지 권한 종류
enum MyPagePermissionType: CaseIterable {
    case camera
    case notification

    /// 권한 타이틀
    var title: String {
        switch self {
        case .camera:
            return "카메라"
        case .notification:
            return "알림"
        }
    }
    
    /// 권한 안내 알림 타이틀
    var alertTitle: String {
        "\(title) 권한 필요"
    }
    
    /// 권한 안내 알림 메시지
    var alertMessage: String {
        "\(title) 사용을 위해 설정에서 권한을 허용해주세요."
    }
}

/// 마이페이지 권한 아이템
struct MyPagePermissionItem: Hashable {
    let type: MyPagePermissionType
    let title: String
    let isAllowed: Bool
}

/// 마이페이지 권한 안내 알림 데이터
struct MyPagePermissionAlertContent {
    let title: String
    let message: String
}

final class MyPagePermissionViewModel: ViewModelProtocol, @unchecked Sendable {

    //MARK: - Properties
    private let disposeBag = DisposeBag()
    private let permissionItemsRelay = BehaviorRelay<[MyPagePermissionItem]>(
        value: []
    )
    private let presentPermissionAlertRelay =
        PublishRelay<MyPagePermissionAlertContent>()
    private let openSettingsRelay = PublishRelay<URL>()

    struct Input {
        /// 화면 진입 이벤트
        let viewDidLoad: Observable<Void>
        /// 화면 재진입 이벤트
        let viewWillAppear: Observable<Void>
        /// 권한 토글 변경 이벤트
        let permissionToggled: Observable<(MyPagePermissionType, Bool)>
    }

    struct Output {
        /// 권한 목록
        let permissionItems: Observable<[MyPagePermissionItem]>
        /// 권한 안내 알림 표시 이벤트
        let presentPermissionAlert: Observable<MyPagePermissionAlertContent>
        /// 설정 앱 이동 이벤트
        let openSettings: Observable<URL>
    }

    func transform(_ input: Input) -> Output {
        Observable.merge(input.viewDidLoad, input.viewWillAppear)
            .subscribe(onNext: { [weak self] in
                self?.updatePermissionItems()
            })
            .disposed(by: disposeBag)

        input.permissionToggled
            .subscribe(onNext: { [weak self] type, isOn in
                self?.handlePermissionToggle(
                    type: type,
                    isOn: isOn
                )
            })
            .disposed(by: disposeBag)

        return Output(
            permissionItems: permissionItemsRelay.asObservable(),
            presentPermissionAlert: presentPermissionAlertRelay.asObservable(),
            openSettings: openSettingsRelay.asObservable()
        )
    }
}

//MARK: - Permission
extension MyPagePermissionViewModel {
    /// 권한 목록 갱신
    func updatePermissionItems() {
        Task { [weak self] in
            guard let self else { return }
            let items = await self.makePermissionItems()

            await MainActor.run {
                self.permissionItemsRelay.accept(items)
            }
        }
    }

    /// 권한 아이템 생성
    func makePermissionItems() async -> [MyPagePermissionItem] {
        var items = [MyPagePermissionItem]()

        for type in MyPagePermissionType.allCases {
            let isAllowed = await isPermissionAllowed(type)
            items.append(
                MyPagePermissionItem(
                    type: type,
                    title: type.title,
                    isAllowed: isAllowed
                )
            )
        }

        return items
    }

    /// 권한 허용 여부
    func isPermissionAllowed(_ type: MyPagePermissionType) async -> Bool {
        switch type {
        case .camera:
            return AVCaptureDevice.authorizationStatus(for: .video) == .authorized

        case .notification:
            let settings = await UNUserNotificationCenter.current()
                .notificationSettings()
            return settings.authorizationStatus == .authorized
        }
    }

    /// 권한 토글 처리
    func handlePermissionToggle(
        type: MyPagePermissionType,
        isOn: Bool
    ) {
        guard isOn else {
            openAppSettings()
            return
        }

        requestPermission(type)
    }

    /// 카메라 권한 요청
    func requestCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] _ in
                self?.updatePermissionItems()
            }
        case .authorized:
            updatePermissionItems()
        default:
            presentPermissionAlert(.camera)
        }
    }

    /// 알림 권한 요청
    func requestNotificationPermission() {
        Task { [weak self] in
            guard let self else { return }
            let settings = await UNUserNotificationCenter.current()
                .notificationSettings()

            switch settings.authorizationStatus {
            case .notDetermined:
                _ = try? await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .badge, .sound])
                self.updatePermissionItems()
            case .authorized:
                self.updatePermissionItems()
            default:
                await MainActor.run {
                    self.presentPermissionAlert(.notification)
                }
            }
        }
    }

    /// 권한 안내 알림 표시
    func presentPermissionAlert(_ type: MyPagePermissionType) {
        presentPermissionAlertRelay.accept(
            MyPagePermissionAlertContent(
                title: type.alertTitle,
                message: type.alertMessage
            )
        )
    }
    
    /// 권한 요청
    func requestPermission(_ type: MyPagePermissionType) {
        switch type {
        case .camera:
            requestCameraPermission()
        case .notification:
            requestNotificationPermission()
        }
    }
    
    /// 앱 설정 열기
    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        openSettingsRelay.accept(url)
    }
}
