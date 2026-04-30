//
//  ProductSelectionViewModel.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/30/26.
//

import Foundation
import RxSwift
import RxCocoa

final class ProductSelectionViewModel: ViewModelProtocol {
    private let disposeBag = DisposeBag()
    private let coreDataManager: CoreDataManagerProtocol
    private let allProductsSubject = BehaviorSubject<[ProductPayload]>(value: [])
    private let selectedIDsSubject: BehaviorSubject<[UUID]>
    
    let confirmCompleted = PublishSubject<[UUID]>()
    
    struct ProductItem: Hashable {
        let id: UUID
        let name: String
        let mainCategory: String
        let isSelected: Bool
        let isEnabled: Bool
    }
    
    init(coreDataManager: CoreDataManagerProtocol, initialSelectedIDs: [UUID]) {
        self.coreDataManager = coreDataManager
        self.selectedIDsSubject = BehaviorSubject(value: initialSelectedIDs)
    }
    
    struct Input {
        let viewWillAppear: Observable<Void>
        let itemTapped: Observable<UUID>
        let confirmButtonTapped: Observable<Void>
    }
    
    struct Output {
        let items: Observable<[ProductItem]>
        let counterText: Observable<String>
    }

    func transform(_ input: Input) -> Output {
        input.viewWillAppear
            .bind(onNext: { [weak self] in
                guard let self else { return }
                let products = (try? self.coreDataManager.fetchAllProducts()) ?? []
                self.allProductsSubject.onNext(products)
            })
            .disposed(by: disposeBag)
        
        input.itemTapped
            .withLatestFrom(selectedIDsSubject) { tappedID, currentIDs -> [UUID] in
                if currentIDs.contains(tappedID) {
                    return currentIDs.filter { $0 != tappedID }
                } else {
                    guard currentIDs.count < 5 else { return currentIDs }
                    return currentIDs + [tappedID]
                }
            }
            .bind(to: selectedIDsSubject)
            .disposed(by: disposeBag)
        
        input.confirmButtonTapped
            .withLatestFrom(selectedIDsSubject)
            .bind(to: confirmCompleted)
            .disposed(by: disposeBag)
        
        let items = Observable.combineLatest(allProductsSubject, selectedIDsSubject) { products, selectedIDs -> [ProductItem] in
            let isFull = selectedIDs.count >= 5
            return products.map { product in
                let isSelected = selectedIDs.contains(product.id)
                let isEnabled = isSelected || !isFull
                return ProductItem(
                    id: product.id,
                    name: product.name,
                    mainCategory: product.mainCategory,
                    isSelected: isSelected,
                    isEnabled: isEnabled
                )
            }
        }
        
        let counterText = selectedIDsSubject.map { "\($0.count) / 5"}
        
        return Output(items: items, counterText: counterText)
    }
}
