//
//  MyPageViewModel.swift
//  JaengYeo
//
//  Created by Codex on 4/20/26.
//

import Foundation
import RxRelay
import RxSwift
import UIKit

/// 마이페이지 섹션 종류
enum MyPageMenuSection: String, CaseIterable {
    case support = "고객 지원"
    case appInfo = "앱 정보"
    case account = "계정"
}

/// 마이페이지 메뉴
enum MyPageMenu: CaseIterable {
    case guide
    case privacyPolicy
    case appPermission
    case feedback
    case appVersion
    case iconCopyright
    case logout
    case deleteAccount

    /// 섹션 타이틀
    var section: MyPageMenuSection {
        switch self {
        case .guide, .privacyPolicy, .appPermission:
            return .support
        case .feedback, .appVersion, .iconCopyright:
            return .appInfo
        case .logout:
            return .account
        case .deleteAccount:
            return .account
        }
    }

    /// 항목 타이틀
    func title(appVersion: String) -> String {
        switch self {
        case .guide:
            return "사용 설명서"
        case .privacyPolicy:
            return "개인정보 처리 방침"
        case .appPermission:
            return "앱 사용 권한 확인"
        case .feedback:
            return "앱 의견 보내기"
        case .appVersion:
            return "현재 버전 \(appVersion)"
        case .iconCopyright:
            return "아이콘 저작권 : icons8"
        case .logout:
            return "로그아웃"
        case .deleteAccount:
            return "회원 탈퇴"
        }
    }

    /// 화살표 표시 여부
    var showsArrow: Bool {
        switch self {
        case .logout, .deleteAccount:
            return false
        default:
            return true
        }
    }
    
    /// 외부 이동 URL
    var externalURL: URL? {
        switch self {
        case .appPermission:
            return URL(string: UIApplication.openSettingsURLString)
        case .appVersion:
            return URL(string: "https://apps.apple.com/app/id0000000000")
        case .iconCopyright:
            return URL(string: "https://icons8.com")
        default:
            return nil
        }
    }
}

/// 마이페이지 섹션
struct MyPageSection: Hashable {
    let title: String
    let items: [MyPageItem]
}

/// 마이페이지 항목
struct MyPageItem: Hashable {
    let menu: MyPageMenu
    let title: String
    let showsArrow: Bool

    init(
        menu: MyPageMenu,
        title: String,
        showsArrow: Bool = true
    ) {
        self.menu = menu
        self.title = title
        self.showsArrow = showsArrow
    }
}

/// 마이페이지 메일 작성 데이터
struct MyPageMailContent {
    let recipients: [String]
    let subject: String
    let body: String
}

final class MyPageViewModel: ViewModelProtocol {

    //MARK: - Properties
    private let disposeBag = DisposeBag()
    private let supportEmail = "jaengyeo09@gmail.com"
    private let authManager: AuthManagerProtocol
    private let coreDataManager: CoreDataManagerProtocol

    init(authManager: AuthManagerProtocol, coreDataManager: CoreDataManagerProtocol) {
        self.authManager = authManager
        self.coreDataManager = coreDataManager
    }

    struct Input {
        /// 화면 진입 이벤트
        let viewDidLoad: Observable<Void>
        /// 마이페이지 항목 선택 이벤트
        let itemSelected: Observable<MyPageItem>
        
        let logoutConfirmed: Observable<Void>
        let deleteAccountConfirmed: Observable<Void>
    }

    struct Output {
        /// 마이페이지 섹션 목록
        let sections: Observable<[MyPageSection]>
        /// 사용 설명서 표시 이벤트
        let showGuide: Observable<Void>
        /// 개인정보 처리방침 표시 이벤트
        let presentPrivacyPolicy: Observable<Void>
        /// 앱 권한 화면 표시 이벤트
        let presentPermission: Observable<Void>
        /// 의견 보내기 메일 작성 이벤트
        let composeFeedbackMail: Observable<MyPageMailContent>
        /// 외부 URL 이동 이벤트
        let openExternalURL: Observable<URL>
        
        let showLogoutConfirm: Observable<Void>
        let logoutCompleted: Observable<Void>
        let showDeleteAccountConfirm: Observable<Void>
        let deleteAccountCompleted: Observable<Void>
    }

    func transform(_ input: Input) -> Output {
        let showGuideRelay = PublishRelay<Void>()
        let presentPrivacyPolicyRelay = PublishRelay<Void>()
        let presentPermissionRelay = PublishRelay<Void>()
        let composeFeedbackMailRelay = PublishRelay<MyPageMailContent>()
        let openExternalURLRelay = PublishRelay<URL>()
        let showLogoutConfirmRelay = PublishRelay<Void>()
        let logoutCompletedRelay = PublishRelay<Void>()
        let showDeleteAccountConfirmRelay = PublishRelay<Void>()
        let deleteAccountCompletedRelay = PublishRelay<Void>()

        let sections = input.viewDidLoad
            .map { [weak self] in
                self?.makeSections() ?? []
            }

        input.itemSelected
            .subscribe(onNext: { [weak self] item in
                guard let self else { return }

                switch item.menu {
                case .guide:
                    showGuideRelay.accept(())

                case .privacyPolicy:
                    presentPrivacyPolicyRelay.accept(())

                case .appPermission:
                    presentPermissionRelay.accept(())

                case .feedback:
                    composeFeedbackMailRelay.accept(makeFeedbackMailContent())

                case .appVersion:
                    if let url = item.menu.externalURL {
                        openExternalURLRelay.accept(url)
                    }

                case .iconCopyright:
                    if let url = item.menu.externalURL {
                        openExternalURLRelay.accept(url)
                    }
                case .logout:
                    showLogoutConfirmRelay.accept(())
                case .deleteAccount:
                    showDeleteAccountConfirmRelay.accept(())
                }
            })
            .disposed(by: disposeBag)
        
        input.logoutConfirmed
            .flatMapLatest { [weak self] _ -> Observable<Void> in
                guard let self else { return .empty() }
                return Observable.create { observer in
                    Task {
                        do {
                            try await self.authManager.signOut()
                            await MainActor.run {
                                observer.onNext(())
                                observer.onCompleted()
                            }
                        } catch {
                            observer.onCompleted()
                        }
                    }
                    return Disposables.create()
                }
            }
            .bind(to: logoutCompletedRelay)
            .disposed(by: disposeBag)

        input.deleteAccountConfirmed
            .flatMapLatest { [weak self] _ -> Observable<Void> in
                guard let self else { return .empty() }
                return Observable.create { observer in
                    Task {
                        do {
                            try await self.authManager.deleteAccount()
                            try? self.coreDataManager.deleteAllUserData()
                            await MainActor.run {
                                observer.onNext(())
                                observer.onCompleted()
                            }
                        } catch {
                            observer.onCompleted()
                        }
                    }
                    return Disposables.create()
                }
            }
            .bind(to: deleteAccountCompletedRelay)
            .disposed(by: disposeBag)

        return Output(
            sections: sections,
            showGuide: showGuideRelay.asObservable(),
            presentPrivacyPolicy: presentPrivacyPolicyRelay.asObservable(),
            presentPermission: presentPermissionRelay.asObservable(),
            composeFeedbackMail: composeFeedbackMailRelay.asObservable(),
            openExternalURL: openExternalURLRelay.asObservable(),
            showLogoutConfirm: showLogoutConfirmRelay.asObservable(),
            logoutCompleted: logoutCompletedRelay.asObservable(),
            showDeleteAccountConfirm: showDeleteAccountConfirmRelay.asObservable(),
            deleteAccountCompleted: deleteAccountCompletedRelay.asObservable()
        )
    }
}

//MARK: - Data
extension MyPageViewModel {
    /// 마이페이지 섹션 생성
    func makeSections() -> [MyPageSection] {
        let groupedMenus = Dictionary(grouping: MyPageMenu.allCases) {
            $0.section
        }

        return MyPageMenuSection.allCases.compactMap { section in
            guard let menus = groupedMenus[section] else { return nil }

            let items = menus.map {
                MyPageItem(
                    menu: $0,
                    title: $0.title(appVersion: appVersion),
                    showsArrow: $0.showsArrow
                )
            }

            return MyPageSection(
                title: section.rawValue,
                items: items
            )
        }
    }

    /// 의견 보내기 메일 내용 생성
    func makeFeedbackMailContent() -> MyPageMailContent {
        MyPageMailContent(
            recipients: [supportEmail],
            subject: "쟁여 문의하기",
            body: """
            아래 내용을 지우지 않고 보내주시면 더 빠르게 확인할 수 있습니다.
            문의 내용과 함께 보내주시면 고맙겠습니다.

            ------------------------------
            앱 버전: \(appVersion) (\(buildVersion))
            기기 정보: \(deviceModel)
            OS 버전: \(systemName) \(systemVersion)
            ------------------------------

            문의 내용:
            """
        )
    }
}

//MARK: - App Info
extension MyPageViewModel {
    /// 앱 버전
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    /// 빌드 버전
    var buildVersion: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
    }

    /// 기기 모델
    var deviceModel: String {
        UIDevice.current.model
    }

    /// OS 이름
    var systemName: String {
        UIDevice.current.systemName
    }

    /// OS 버전
    var systemVersion: String {
        UIDevice.current.systemVersion
    }
}
