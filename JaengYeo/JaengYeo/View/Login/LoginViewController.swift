//
//  LoginViewController.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/20/26.
//

import UIKit
import AuthenticationServices
import CryptoKit
import RxSwift
import RxCocoa

final class LoginViewController: BaseViewController {
    
    private let disposeBag = DisposeBag()
    
    private let mainView = LoginView()
    private let viewModel: LoginViewModel
    
    private var currentNonce: String?
    
    init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = mainView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
    }
}

extension LoginViewController {
    private func bind() {
        let output = viewModel.transform(.init())
        
        mainView.appleLoginButton.rx
            .controlEvent(.touchUpInside)
            .bind(onNext: { [weak self] in
                self?.startAppleLogin()
            })
            .disposed(by: disposeBag)
        
        output.error
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] message in
                self?.showErrorAlert(title: "에러", message: message)
            })
            .disposed(by: disposeBag)
    }
}

extension LoginViewController {
    private func startAppleLogin() {
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(input: nonce)
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        let charSet: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            guard status == errSecSuccess else { continue }
            
            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charSet.count {
                    result.append(charSet[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }
    
    private func sha256(input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

extension LoginViewController: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8),
              let nonce = currentNonce else { return }
        
        viewModel.appleCredentialReceived.onNext((idToken: idToken, nonce: nonce))
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: any Error) {
        guard (error as? ASAuthorizationError)?.code != .canceled else { return }
        viewModel.errorSubject.onNext("Apple 로그인 중 오류가 발생했습니다.")
    }
}

extension LoginViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        view.window!
    }
}

extension LoginViewController {
    private func showErrorAlert(title: String, message: String) {
        let alert = AlertController(
            image: .warningIcon,
            title: title,
            message: message,
            actions: [.default("확인")]
        )
        present(alert, animated: true)
    }
}
