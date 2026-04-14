//
//  RegisterDetailViewModel.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/13/26.
//

import UIKit
import RxSwift
import RxCocoa

final class RegisterDetailViewModel: ViewModelProtocol {
    
    enum CategoryType { case food, household }
    
    struct Input {
        let foodCategoryTapped: Observable<Void>
        let householdCategoryTapped: Observable<Void>
        let fieldsSelected: Observable<Set<RegisterOptionField>>
        let stockPlusTapped: Observable<Void>
        let stockMinusTapped: Observable<Void>
        let confirmTapped: Observable<RegisterFormData>
        let imagePicked: Observable<UIImage>
        let midCategorySelected: Observable<UUID?>
        let subCategorySelected: Observable<UUID?>
    }
    
    struct Output {
        let selectedCategory: Observable<CategoryType?>
        let selectedFields: Observable<Set<RegisterOptionField>>
        let stockAlertValue: Observable<String>
        let confirmError: Observable<String>
        let didConfirm: Observable<RegisterFormData>
        let selectedImage: Observable<UIImage?>
    }
    
    let item: RegisterFormData
    private let selectedCategorySubject: BehaviorSubject<CategoryType?>
    private let selectedFieldsSubject: BehaviorSubject<Set<RegisterOptionField>>
    private let stockValueSubject: BehaviorSubject<Int>
    private lazy var imageSubject = BehaviorSubject<UIImage?>(value: item.image)
    
    var currentFields: Set<RegisterOptionField> {
        (try? selectedFieldsSubject.value()) ?? []
    }
    private let disposeBag = DisposeBag()
    
    init(item: RegisterFormData) {
        self.item = item
        
        let initialCategory: CategoryType? = {
            switch item.mainCategory {
            case "식재료": return .food
            case "생활용품": return .household
            default: return nil
            }
        }()
        self.selectedCategorySubject = BehaviorSubject(value: initialCategory)
        self.selectedFieldsSubject = BehaviorSubject(value: item.selectedFields)
        self.stockValueSubject = BehaviorSubject(value: item.lowStockThreshold ?? 0)
    }
    
    func transform(_ input: Input) -> Output {
        let confirmErrorSubject = PublishSubject<String>()
        let didConfirmSubject = PublishSubject<RegisterFormData>()
        let midCategorySubject = BehaviorSubject<UUID?>(value: item.midCategory)
        let subCategorySubject = BehaviorSubject<UUID?>(value: item.subCategory)
        
        input.foodCategoryTapped
            .map { CategoryType.food }
            .bind(onNext: { [weak self] in self?.selectedCategorySubject.onNext($0) })
            .disposed(by: disposeBag)
        
        input.householdCategoryTapped
            .map { CategoryType.household }
            .bind(onNext: { [weak self] in self?.selectedCategorySubject.onNext($0) })
            .disposed(by: disposeBag)
        
        input.fieldsSelected
            .bind(to: selectedFieldsSubject)
            .disposed(by: disposeBag)
        
        input.stockPlusTapped
            .withLatestFrom(stockValueSubject)
            .map { $0 + 1 }
            .bind(to: stockValueSubject)
            .disposed(by: disposeBag)
        
        input.stockMinusTapped
            .withLatestFrom(stockValueSubject)
            .filter { $0 > 0 }
            .map { $0 - 1 }
            .bind(to: stockValueSubject)
            .disposed(by: disposeBag)
        
        input.confirmTapped
            .withLatestFrom(
                Observable.combineLatest(
                    selectedCategorySubject,
                    selectedFieldsSubject,
                    stockValueSubject,
                    imageSubject,
                    midCategorySubject,
                    subCategorySubject
                )
            ) { item, state in (item, state.0, state.1, state.2, state.3, state.4, state.5) }
            .bind(onNext: { item, category, fields, stock, image, midCategory, subCategory in
                let mainCategory = category == .food ? "식재료" : category == .household ? "생활용품" : nil
                guard item.name?.isEmpty == false, mainCategory != nil else {
                    confirmErrorSubject.onNext(("이름과 카테고리를 입력해주세요."))
                    return
                }
                var result = item
                result.mainCategory = mainCategory
                result.image = image
                result.midCategory = midCategory
                result.subCategory = subCategory
                if fields.contains(.stockAlert) {
                    result.lowStockThreshold = stock
                    result.isLowStockNotificationEnabled = stock > 0
                }
                result.selectedFields = fields
                didConfirmSubject.onNext(result)
            })
            .disposed(by: disposeBag)
        
        input.imagePicked
            .bind(onNext: { [weak self] image in
                self?.imageSubject.onNext(image)
            })
            .disposed(by: disposeBag)
        
        input.midCategorySelected
            .bind(to: midCategorySubject)
            .disposed(by: disposeBag)
        
        input.subCategorySelected
            .bind(to: subCategorySubject)
            .disposed(by: disposeBag)
        
        return Output(
            selectedCategory: selectedCategorySubject.asObservable(),
            selectedFields: selectedFieldsSubject.asObservable(),
            stockAlertValue: stockValueSubject.map { String($0) },
            confirmError: confirmErrorSubject.asObservable(),
            didConfirm: didConfirmSubject.asObservable(),
            selectedImage: imageSubject.asObservable()
        )
    }
}
