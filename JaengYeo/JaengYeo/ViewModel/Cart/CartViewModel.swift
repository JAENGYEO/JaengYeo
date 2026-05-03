//
//  CartViewModel.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/28/26.
//

import Foundation
import RxSwift
import RxRelay

final class CartViewModel: ViewModelProtocol {

    //MARK: - Properties
    private let disposeBag = DisposeBag()
    private var cartItemObservationDisposeBag = DisposeBag()
    private let coreDataManager: CoreDataManagerProtocol
    private let cartItemsRelay = BehaviorRelay<[CartItem]>(value: [])
    
    struct Input {
        /// 화면 로드 이벤트
        let viewDidLoad: Observable<Void>
        /// 장바구니 아이템 삭제 이벤트
        let itemDeleted: Observable<CartItem>
        /// 장바구니 아이템 수량 증가 이벤트
        let itemQuantityIncreased: Observable<CartItem>
        /// 장바구니 아이템 수량 감소 이벤트
        let itemQuantityDecreased: Observable<CartItem>
    }
    
    struct Output {
        /// 장바구니 아이템 목록
        let cartItems: Observable<[CartItem]>
        /// 장바구니 비어있는지 여부
        let isEmpty: Observable<Bool>
        /// 장바구니 아이템 개수
        let totalCountText: Observable<Int>
    }
    
    func transform(_ input: Input) -> Output {
        input.viewDidLoad
            .subscribe(onNext: { [weak self] in
                self?.bindCartItems()
            })
            .disposed(by: disposeBag)

        input.itemDeleted
            .subscribe(onNext: { [weak self] item in
                try? self?.coreDataManager.deleteCartItem(id: item.id)
            })
            .disposed(by: disposeBag)

        input.itemQuantityIncreased
            .subscribe(onNext: { [weak self] item in
                self?.updateCartItem(item.increased())
            })
            .disposed(by: disposeBag)

        input.itemQuantityDecreased
            .subscribe(onNext: { [weak self] item in
                self?.updateCartItem(item.decreased())
            })
            .disposed(by: disposeBag)
        
        return Output(
            cartItems: cartItemsRelay.asObservable(),
            isEmpty: cartItemsRelay
                .map { $0.isEmpty }
                .asObservable(),
            totalCountText: cartItemsRelay
                .map { $0.count }
                .asObservable()
        )
    }
    
    //MARK: - Init
    init(coreDataManager: CoreDataManagerProtocol) {
        self.coreDataManager = coreDataManager
    }
}

//MARK: - Binding
private extension CartViewModel {
    /// 장바구니 아이템 변경 관찰
    func bindCartItems() {
        cartItemObservationDisposeBag = DisposeBag()
        
        coreDataManager.observeCartItems(
            sortDescriptors: [
                NSSortDescriptor(
                    key: "createDate",
                    ascending: false
                )
            ]
        )
        .map { $0.map { $0.toDomain } }
        .bind(to: cartItemsRelay)
        .disposed(by: cartItemObservationDisposeBag)
    }

    /// 장바구니 아이템 갱신
    func updateCartItem(_ item: CartItem) {
        try? coreDataManager.updateCartItem(item.toPayload)
    }
}
