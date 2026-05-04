//
//  CartAddItemViewModel.swift
//  JaengYeo
//
//  Created by Hanjuheon on 5/3/26.
//

import Foundation
import RxCocoa
import RxRelay
import RxSwift

final class CartAddItemViewModel: ViewModelProtocol {

    //MARK: - Properties
    let item: CartItem?
    private let disposeBag = DisposeBag()
    private let coreDataManager: CoreDataManagerProtocol
    private let selectedMainCategorySubject: BehaviorSubject<MainCategory?>

    var navigationTitle: String {
        item == nil ? "신규 등록" : "수정"
    }

    var isEditMode: Bool {
        item != nil
    }

    struct Input {
        /// 식재료 버튼 탭 이벤트
        let foodCategoryTapped: Observable<Void>
        /// 생활용품 버튼 탭 이벤트
        let householdCategoryTapped: Observable<Void>
        /// 저장 버튼 탭 이벤트
        let confirmTapped: Observable<CartAddItemFormData>
        /// 삭제 버튼 탭 이벤트
        let deleteTapped: Observable<Void>
    }

    struct Output {
        /// 선택된 대분류
        let selectedCategory: Observable<MainCategory?>
        /// 필수 입력 에러
        let confirmError: Observable<String>
        /// 저장 완료 이벤트
        let didConfirm: Observable<Void>
        /// 삭제 완료 이벤트
        let didDelete: Observable<Void>
        /// 에러 메시지
        let error: Observable<String>
    }

    //MARK: - Init
    init(coreDataManager: CoreDataManagerProtocol, item: CartItem? = nil) {
        self.coreDataManager = coreDataManager
        self.item = item

        let initialCategory = item.flatMap {
            MainCategory(rawValue: $0.mainCategory)
        }
        self.selectedMainCategorySubject = BehaviorSubject(
            value: initialCategory
        )
    }

    func transform(_ input: Input) -> Output {
        let confirmErrorSubject = PublishSubject<String>()
        let didConfirmSubject = PublishSubject<Void>()
        let didDeleteSubject = PublishSubject<Void>()
        let errorSubject = PublishSubject<String>()

        input.foodCategoryTapped
            .bind(onNext: { [weak self] in
                self?.selectedMainCategorySubject.onNext(.foodstuff)
            })
            .disposed(by: disposeBag)

        input.householdCategoryTapped
            .bind(onNext: { [weak self] in
                self?.selectedMainCategorySubject.onNext(.household)
            })
            .disposed(by: disposeBag)

        input.confirmTapped
            .withLatestFrom(selectedMainCategorySubject) { formData, category in
                (formData, category)
            }
            .bind(onNext: { [weak self] formData, category in
                guard let self else { return }
                guard let item = makeCartItem(
                    formData: formData,
                    mainCategory: category,
                    confirmErrorSubject: confirmErrorSubject
                ) else { return }

                do {
                    if self.item == nil {
                        try coreDataManager.createCartItem(item.toPayload)
                    } else {
                        try coreDataManager.updateCartItem(item.toPayload)
                    }
                    didConfirmSubject.onNext(())
                } catch {
                    errorSubject.onNext("구매 예정 항목을 저장하는 중 오류가 발생했습니다.")
                }
            })
            .disposed(by: disposeBag)

        input.deleteTapped
            .bind(onNext: { [weak self] in
                guard let self, let item else { return }

                do {
                    try coreDataManager.deleteCartItem(id: item.id)
                    didDeleteSubject.onNext(())
                } catch {
                    errorSubject.onNext("구매 예정 항목을 삭제하는 중 오류가 발생했습니다.")
                }
            })
            .disposed(by: disposeBag)

        return Output(
            selectedCategory: selectedMainCategorySubject.asObservable(),
            confirmError: confirmErrorSubject.asObservable(),
            didConfirm: didConfirmSubject.asObservable(),
            didDelete: didDeleteSubject.asObservable(),
            error: errorSubject.asObservable()
        )
    }
}

//MARK: - Validate
private extension CartAddItemViewModel {
    func makeCartItem(
        formData: CartAddItemFormData,
        mainCategory: MainCategory?,
        confirmErrorSubject: PublishSubject<String>
    ) -> CartItem? {
        guard formData.name.isEmpty == false else {
            confirmErrorSubject.onNext("이름을 입력해주세요.")
            return nil
        }

        guard let quantity = formData.quantity else {
            confirmErrorSubject.onNext("수량을 입력해주세요.")
            return nil
        }

        guard quantity != 0 else {
            confirmErrorSubject.onNext("수량은 최소 1개 이상이어야 합니다.")
            return nil
        }

        guard let mainCategory else {
            confirmErrorSubject.onNext("메인 카테고리를 선택해주세요.")
            return nil
        }

        return CartItem(
            id: item?.id ?? UUID(),
            referenceId: item?.referenceId,
            name: formData.name,
            mainCategory: mainCategory.rawValue,
            quantity: quantity,
            createdAt: item?.createdAt ?? Date()
        )
    }
}

//MARK: - FormData
struct CartAddItemFormData {
    let name: String
    let quantity: Int?
}
