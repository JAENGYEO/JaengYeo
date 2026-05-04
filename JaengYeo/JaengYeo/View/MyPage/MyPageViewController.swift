//
//  MyPageViewController.swift
//  JaengYeo
//
//  Created by Codex on 4/20/26.
//

import AuthenticationServices
import MessageUI
import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

protocol MyPageViewControllerDelegate: AnyObject {
    func didLogout()
    func didTapWidgetSetting()
}

final class MyPageViewController: BaseViewController {

    //MARK: - ViewModel
    private let viewModel: MyPageViewModel

    //MARK: - Properties
    private let disposeBag = DisposeBag()

    //MARK: - Components
    private let myPageView = MyPageView()
    
    weak var delegate: MyPageViewControllerDelegate?
    private let logoutConfirmRelay = PublishRelay<Void>()
    private let deleteAccountConfirmRelay = PublishRelay<String>()

    //MARK: - Init
    init(viewModel: MyPageViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = myPageView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        bind()
    }
}

//MARK: - Binding
extension MyPageViewController {
    func bind() {
        let input = MyPageViewModel.Input(
            viewDidLoad: Observable.just(()),
            itemSelected: myPageView.itemSelected,
            logoutConfirmed: logoutConfirmRelay.asObservable(),
            deleteAccountConfirmed: deleteAccountConfirmRelay.asObservable()
        )

        let output = viewModel.transform(input)

        /// 마이페이지 목록 바인딩
        output.sections
            .bind(onNext: { [weak self] sections in
                self?.myPageView.applySnapshot(with: sections)
            })
            .disposed(by: disposeBag)

        /// 사용 설명서 표시
        output.showGuide
            .bind(onNext: { [weak self] in
                self?.pushGuide()
            })
            .disposed(by: disposeBag)

        /// 개인정보 처리방침 표시
        output.presentPrivacyPolicy
            .bind(onNext: { [weak self] in
                self?.presentPolicy()
            })
            .disposed(by: disposeBag)

        /// 앱 권한 화면 표시
        output.presentPermission
            .bind(onNext: { [weak self] in
                self?.pushPermission()
            })
            .disposed(by: disposeBag)
        
        output.presentWidgetSetting
            .bind(onNext: { [weak self] in
                self?.delegate?.didTapWidgetSetting()
            })
            .disposed(by: disposeBag)

        /// 의견 보내기 메일 작성
        output.composeFeedbackMail
            .bind(onNext: { [weak self] content in
                self?.presentMailComposer(content)
            })
            .disposed(by: disposeBag)

        /// 외부 URL 열기
        output.openExternalURL
            .bind(onNext: { url in
                UIApplication.shared.open(url)
            })
            .disposed(by: disposeBag)
        
        output.showLogoutConfirm
            .bind(onNext: { [weak self] in
                self?.showLogoutAlert()
            })
            .disposed(by: disposeBag)
        
        output.logoutCompleted
            .bind(onNext: { [weak self] in
                self?.delegate?.didLogout()
            })
            .disposed(by: disposeBag)

        output.showDeleteAccountConfirm
            .bind(onNext: { [weak self] in
                self?.showDeleteAccountAlert()
            })
            .disposed(by: disposeBag)

        output.deleteAccountCompleted
            .bind(onNext: { [weak self] in
                self?.delegate?.didLogout()
            })
            .disposed(by: disposeBag)
    }
}

//MARK: - Present
extension MyPageViewController {
    /// 사용설명서 화면 이동
    func pushGuide() {
        let viewController = OnboardingViewController()
        navigationController?.pushViewController(viewController, animated: true)
    }

    /// 앱 권한 화면 이동
    func pushPermission() {
        let viewController = MyPagePermissionViewController(
            viewModel: MyPagePermissionViewModel()
        )
        navigationController?.pushViewController(
            viewController,
            animated: true
        )
    }
    
    /// 개인정보 처리방침 모달 표시
    func presentPolicy() {
        let viewController = MyPagePolicyViewController(
            viewModel: MyPagePolicyViewModel()
        )
        viewController.modalPresentationStyle = .pageSheet
        present(viewController, animated: true)
    }

    /// 메일 작성 화면 표시
    func presentMailComposer(_ content: MyPageMailContent) {
        guard MFMailComposeViewController.canSendMail() else {
            presentMailUnavailableAlert()
            return
        }

        let viewController = MFMailComposeViewController()
        viewController.mailComposeDelegate = self
        viewController.setToRecipients(content.recipients)
        viewController.setSubject(content.subject)
        viewController.setMessageBody(content.body, isHTML: false)
        present(viewController, animated: true)
    }

    /// 메일 앱 미설정 알림
    func presentMailUnavailableAlert() {
        AlertController.rx.alert(
            on: self,
            image: UIImage(named: "alertRed") ?? UIImage(),
            title: "메일 앱 확인",
            message: "메일 앱 설정 후 다시 시도해주세요.",
            actions: [.default("확인")]
        )
        .subscribe()
        .disposed(by: disposeBag)
    }
}

//MARK: - Configure
extension MyPageViewController {
    /// 네비게이션 바 설정
    func configureNavigationBar() {
        title = "마이페이지"

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .font: LabelConfiguration.titleSemi18.font,
            .foregroundColor: UIColor.gray800
        ]

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .gray800
    }
}

//MARK: - MFMailComposeViewControllerDelegate
extension MyPageViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        controller.dismiss(animated: true)
    }
}

extension MyPageViewController {
    private func showLogoutAlert() {
        AlertController.rx.alert(
            on: self,
            image: UIImage(named: "alertRed") ?? UIImage(),
            title: "로그아웃",
            message: "로그아웃 하시겠습니까?",
            actions: [.cancel("취소"), .destructive("로그아웃")]
        )
        .subscribe(onNext: { [weak self] action in
            if action.style == .destructive {
                self?.logoutConfirmRelay.accept(())
            }
        })
        .disposed(by: disposeBag)
    }

    private func showDeleteAccountAlert() {
        AlertController.rx.alert(
            on: self,
            image: UIImage(named: "alertRed") ?? UIImage(),
            title: "회원 탈퇴",
            message: "탈퇴 시 모든 데이터가 영구 삭제되며\n복구할 수 없습니다.",
            actions: [.cancel("취소"), .destructive("탈퇴")]
        )
        .subscribe(onNext: { [weak self] action in
            if action.style == .destructive {
                self?.requestAppleAuthorizationCode()
            }
        })
        .disposed(by: disposeBag)
    }

    private func requestAppleAuthorizationCode() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = []

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
}

extension MyPageViewController: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let codeData = credential.authorizationCode,
              let code = String(data: codeData, encoding: .utf8) else { return }
        deleteAccountConfirmRelay.accept(code)
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: any Error
    ) {}
}

extension MyPageViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        view.window!
    }
}
