//
//  ProductGroupListViewModel.swift
//  JaengYeo
//
//  Created by Codex on 4/19/26.
//

import Foundation
import RxSwift

final class ProductGroupListViewModel: ViewModelProtocol {

    //MARK: - Properties
    /// 그룹 상품 목록
    private let items: [ProductCellItem]

    struct Input {
        /// 화면 로드 이벤트
        let viewDidLoad: Observable<Void>
        /// 상품 선택 이벤트
        let itemSelected: Observable<ProductCellItem>
    }

    struct Output {
        /// 총 수량 텍스트
        let totalCountText: Observable<String>
        /// 그룹 상품 목록
        let items: Observable<[ProductCellItem]>
        /// 선택된 상품 ID
        let selectedProductID: Observable<UUID>
    }

    //MARK: - Init
    init(items: [ProductCellItem]) {
        self.items = items
    }

    func transform(_ input: Input) -> Output {
        let items = input.viewDidLoad
            .map { [items] in items }

        let selectedProductID = input.itemSelected
            .map { $0.product.id }

        return Output(
            totalCountText: .just("총 \(totalQuantity)개"),
            items: items,
            selectedProductID: selectedProductID
        )
    }
}

//MARK: - Data
private extension ProductGroupListViewModel {
    /// 총 수량
    var totalQuantity: Int {
        items.reduce(0) { $0 + $1.product.quantity }
    }
}
