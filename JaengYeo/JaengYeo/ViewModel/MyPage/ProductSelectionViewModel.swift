//
//  ProductSelectionViewModel.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/30/26.
//

import Foundation
import RxSwift
import RxCocoa
import UIKit

final class ProductSelectionViewModel: ViewModelProtocol {
    private let disposeBag = DisposeBag()
    private let coreDataManager: CoreDataManagerProtocol
    private let allProductsSubject = BehaviorSubject<[ProductPayload]>(value: [])
    private let selectedIDsSubject: BehaviorSubject<[UUID]>
    
    let confirmCompleted = PublishSubject<[UUID]>()
    
    struct ProductItem: Hashable {
        let id: UUID
        let name: String
        let image: UIImage?
        let subCategoryIconName: String?
        let expiryDaysLeft: Int?
        let midCategoryName: String?
        let subCategoryName: String?
        let quantity: Int
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
        let searchKeyword: Observable<String>
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
        
        let searchKeyword = input.searchKeyword.startWith("")
        
        let items = Observable.combineLatest(allProductsSubject, selectedIDsSubject, searchKeyword).map { [weak self] products, selectedIDs, keyword -> [ProductItem] in
            guard let self else { return [] }
            let isFull = selectedIDs.count >= 5
            let trimmed = keyword.trimmingCharacters(in: .whitespaces).lowercased()
            let filterd = trimmed.isEmpty ? products : products.filter {
                $0.name.lowercased().contains(trimmed)
            }
            
            return filterd.map { product in
                let isSelected = selectedIDs.contains(product.id)
                let isEnabled = isSelected || !isFull
                let image = ImageUtils.loadImage(fileName: product.imageUrl)
                let iconName: String?
                if image == nil,
                   let subCategoryId = product.subCategoryId,
                   let subCategory = try? self.coreDataManager.fetchSubCategory(of: subCategoryId) {
                    iconName = subCategory.iconName
                } else {
                    iconName = nil
                }
                
                let expiryDaysLeft: Int?
                if let expiryDate = product.expiryDate {
                    let today = Calendar.current.startOfDay(for: Date())
                    let expiryDay = Calendar.current.startOfDay(for: expiryDate)
                    expiryDaysLeft = Calendar.current.dateComponents([.day], from: today, to: expiryDay).day
                } else {
                    expiryDaysLeft = nil
                }
                
                let midCategoryName = product.midCategoryId.flatMap {
                    try? self.coreDataManager.fetchMidCategory(of: $0).name
                }
                let subCategoryName = product.subCategoryId.flatMap {
                    try? self.coreDataManager.fetchSubCategory(of: $0).name
                }
                
                return ProductItem(
                    id: product.id,
                    name: product.name,
                    image: image,
                    subCategoryIconName: iconName,
                    expiryDaysLeft: expiryDaysLeft,
                    midCategoryName: midCategoryName,
                    subCategoryName: subCategoryName,
                    quantity: Int(product.quantity),
                    isSelected: isSelected,
                    isEnabled: isEnabled
                )
            }
        }
        
        let counterText = selectedIDsSubject.map { "선택된 상품 \($0.count)/5"}
        
        return Output(items: items, counterText: counterText)
    }
}
