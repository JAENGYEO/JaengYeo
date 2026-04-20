//
//  RegisterViewModel.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/9/26.
//

import Foundation
import RxSwift
import Supabase
import UIKit

final class RegisterViewModel: ViewModelProtocol {
    
    private let client: SupabaseClient
    private let receiptAnalyzer: ReceiptProtocol
    private let disposeBag = DisposeBag()
    
    init(client: SupabaseClient, receiptAnalyzer: ReceiptProtocol) {
        self.client = client
        self.receiptAnalyzer = receiptAnalyzer
    }
    
    struct Input {
        let aiCaptured: PublishSubject<Data>
        let receiptCaptured: PublishSubject<UIImage>
        let barcodeCaptured: PublishSubject<[String]>
    }
    
    struct Output {
        let aiResponseData: Observable<[RegisterFormData]>
        let receiptResponseData: Observable<[RegisterFormData]>
        let barcodeResponseData: Observable<[RegisterFormData]>
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
        
        let receiptResponseData = input.receiptCaptured
            .do(onNext: { _ in isLoadingSubject.onNext(true) })
            .flatMapLatest { [weak self] image -> Observable<[RegisterFormData]> in
                guard let self else { return .empty() }
                return Observable.create { observer in
                    let task = Task {
                        do {
                            let items = try await self.receiptAnalyzer.analyzeReceipt(image: image)
                            observer.onNext(items)
                            isLoadingSubject.onNext(false)
                            observer.onCompleted()
                        } catch {
                            isLoadingSubject.onNext(false)
                            errorSubject.onNext("영수증 인식 실패")
                            observer.onCompleted()
                        }
                    }
                    return Disposables.create {
                        task.cancel()
                    }
                }
            }
        
        let barcodeResponseData = input.barcodeCaptured
            .do(onNext: { _ in isLoadingSubject.onNext(true) })
            .flatMapLatest { [weak self] codes -> Observable<[RegisterFormData]> in
                return Observable.create { observer in
                    let task = Task {
                        let items = await withTaskGroup(of: RegisterFormData?.self) { group in
                            for code in codes {
                                group.addTask { try? await self?.lookupBarcode(code: code)}
                            }
                            var results: [RegisterFormData] = []
                            for await item in group {
                                if let item { results.append(item) }
                            }
                            return results
                        }
                        isLoadingSubject.onNext(false)
                        if items.isEmpty {
                            errorSubject.onNext("바코드 인식 실패")
                        } else {
                            observer.onNext(items)
                        }
                        observer.onCompleted()
                    }
                    return Disposables.create {
                        task.cancel()
                    }
                }
            }
        
        
        return Output(
            aiResponseData: aiResponseData,
            receiptResponseData: receiptResponseData,
            barcodeResponseData: barcodeResponseData,
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

extension RegisterViewModel {
    private struct BarcodeResponse: Decodable {
        let productName: String?
        let manufacturer: String?
        let barcode: String
    }
    
    private func fetchBarcodeResponse(code: String) async throws -> BarcodeResponse {
        let body: [String: AnyJSON] = ["barcode": AnyJSON(stringLiteral: code)]
        return try await client.functions
            .invoke("barcode-lookup", options: FunctionInvokeOptions(body: body))
    }
    
    private func lookupBarcode(code: String) async throws -> RegisterFormData {
        let response = try await fetchBarcodeResponse(code: code)
        var form = RegisterFormData()
        form.name = response.productName
        form.brand = response.manufacturer
        return form
        
    }
}
