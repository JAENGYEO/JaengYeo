//
//  LoginViewModel.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/20/26.
//

import Foundation
import RxSwift
import RxCocoa

final class LoginViewModel: ViewModelProtocol {
    
    private let authManager: AuthManagerProtocol
    private let disposeBag = DisposeBag()
    
    let appleCredentialReceived = PublishSubject<(idToken: String, nonce: String)>()
    let loginCompleted = PublishRelay<Void>()
    
    let errorSubject = PublishSubject<String>()
    let isLoadingSubject = PublishSubject<Bool>()
    
    init(authManager: AuthManagerProtocol) {
        self.authManager = authManager
    }
    
    struct Input {}
    
    struct Output {
        let loginCompleted: Observable<Void>
        let error: Observable<String>
        let isLoading: Observable<Bool>
    }
    
    func transform(_ input: Input) -> Output {
        appleCredentialReceived
            .do(onNext: { _ in self.isLoadingSubject.onNext(true) })
            .flatMapLatest { [weak self] (idToken, nonce) -> Observable<Void> in
                guard let self else { return .empty() }
                return Observable.create { observer in
                    Task {
                        do {
                            try await self.authManager.signInWithApple(idToken: idToken, nonce: nonce)
                            self.isLoadingSubject.onNext(false)
                            observer.onNext(())
                            observer.onCompleted()
                        } catch {
                            self.isLoadingSubject.onNext(false)
                            self.errorSubject.onNext("로그인에 실패했습니다.")
                            observer.onCompleted()
                        }
                    }
                    return Disposables.create()
                }
            }
            .bind(to: loginCompleted)
            .disposed(by: disposeBag)
        
        return Output(
            loginCompleted: loginCompleted.asObservable(),
            error: errorSubject.asObservable(),
            isLoading: isLoadingSubject.asObservable()
        )
    }
}
