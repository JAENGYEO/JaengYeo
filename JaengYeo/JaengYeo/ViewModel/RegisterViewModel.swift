//
//  RegisterViewModel.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/9/26.
//

import Foundation
import RxSwift
import Supabase

final class RegisterViewModel: ViewModelProtocol {
    
    private let client: SupabaseClient
    private let disposeBag = DisposeBag()
    
    init(client: SupabaseClient) {
        self.client = client
    }
    
    struct Input {
        let aiCaptured: PublishSubject<Data>
    }
    
    struct Output {
        let aiResponseData: Observable<[RegisterFormData]>
        let isLoading: Observable<Bool>
        let error: Observable<String>
    }
    
    func transform(_ input: Input) -> Output {
        let isLoadingSubject = PublishSubject<Bool>()
        let errorSubject = PublishSubject<String>()
        
        let aiResponseData = input.aiCaptured
            .do(onNext: { _ in isLoadingSubject.onNext(true) })
            .flatMapLatest { [weak self] data -> Observable<[RegisterFormData]> in
                guard let self else { return .empty() }
                let base64 = data.base64EncodedString()
                return Observable.create { observer in
                    Task {
                        do {
                            let response = try await self.analyzeByAi(base64: base64)
                            let formDataList = self.aiResponseToFromData(response: response)
                            observer.onNext(formDataList)
                            isLoadingSubject.onNext(false)
                            observer.onCompleted()
                        } catch {
                            isLoadingSubject.onNext(false)
                            errorSubject.onNext("AI 분석 실패")
                            observer.onCompleted()
                        }
                    }
                    return Disposables.create()
                }
            }
        return Output(
            aiResponseData: aiResponseData,
            isLoading: isLoadingSubject.asObservable(),
            error: errorSubject.asObservable()
        )
    }
}

extension RegisterViewModel {
    // Supabase에 보낼 body 구성, invoke로 api 호출
    private func analyzeByAi(base64: String) async throws -> AIResponse {
        let body: [String: AnyJSON] = [
            "imageBase64": AnyJSON(stringLiteral: base64),
            "mimeType": AnyJSON(stringLiteral: "image/jpeg")
        ]
        return try await client.functions
            .invoke("gpt-vision", options: FunctionInvokeOptions(body: body))
    }
    
    // analyzeByAi로 받아온 데이터 FormData화
    private func aiResponseToFromData(response: AIResponse) -> [RegisterFormData] {
        return response.items.map { item in
            var form = RegisterFormData()
            form.name = item.name
            form.mainCategory = item.estimatedCategory
            form.quantity = item.estimatedQuantity
            return form
        }
    }
}
