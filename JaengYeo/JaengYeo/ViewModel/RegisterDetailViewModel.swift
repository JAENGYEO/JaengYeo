//
//  RegisterDetailViewModel.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/13/26.
//

import Foundation
import RxSwift
import RxCocoa

final class RegisterDetailViewModel: ViewModelProtocol {
    
    typealias CategoryType = RegisterDetailView.CategoryType
    
    struct Input {
        let foodCategoryTapped: Observable<Void>
        let householdCategoryTapped: Observable<Void>
        let fieldsSelected: Observable<Set<RegisterOptionField>>
        let stockPlusTapped: Observable<Void>
        let stockMinusTapped: Observable<Void>
        let confirmTapped: Observable<RegisterFormData>
    }
    
    struct Output {
        let selectedCategory: Observable<CategoryType?>
        let selectedFields: Observable<Set<RegisterOptionField>>
        let stockAlertValue: Observable<String>
        let confirmError: Observable<Void>
        let didConfirm: Observable<RegisterFormData>
    }
    
    let item: RegisterFormData
    private let selectedCategorySubject: BehaviorSubject<CategoryType?>
    private let selectedFieldsSubject: BehaviorSubject<Set<RegisterOptionField>>
    private let stockValueSubject: BehaviorSubject<Int>
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
        let confirmErrorSubject = PublishSubject<Void>()
        let didConfirmSubject = PublishSubject<RegisterFormData>()
        
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
                Observable.combineLatest(selectedCategorySubject, selectedFieldsSubject, stockValueSubject)
            ) { item, state in (item, state.0, state.1, state.2) }
            .bind(onNext: { item, category, fields, stock in
                let mainCategory = category == .food ? "식재료" : category == .household ? "생활용품" : nil
                guard item.name?.isEmpty == false, mainCategory != nil else {
                    confirmErrorSubject.onNext(())
                    return
                }
                var result = item
                result.mainCategory = mainCategory
                if fields.contains(.stockAlert) {
                    result.lowStockThreshold = stock
                    result.isLowStockNotificationEnabled = stock > 0
                }
                result.selectedFields = fields
                didConfirmSubject.onNext(result)
            })
            .disposed(by: disposeBag)
        
        return Output(
            selectedCategory: selectedCategorySubject.asObservable(),
            selectedFields: selectedFieldsSubject.asObservable(),
            stockAlertValue: stockValueSubject.map { String($0) },
            confirmError: confirmErrorSubject.asObservable(),
            didConfirm: didConfirmSubject.asObservable()
        )
    }
}
