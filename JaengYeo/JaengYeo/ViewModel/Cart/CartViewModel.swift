//
//  CartViewModel.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/28/26.
//

import Foundation
import RxSwift
import RxRelay

//MARK: - Sort
enum CartSortOption: String, CaseIterable {
    case nameAsc = "이름순"
    case nameDesc = "이름 역순"
    case createdAtDesc = "등록일 최신순"
    case createdAtAsc = "등록일 오래된순"
    case quantityDesc = "수량 많은 순"
    case quantityAsc = "수량 적은 순"
}

final class CartViewModel: ViewModelProtocol {

    //MARK: - Properties
    private let disposeBag = DisposeBag()
    private var cartItemObservationDisposeBag = DisposeBag()
    private let coreDataManager: CoreDataManagerProtocol
    private let cartItemsRelay = BehaviorRelay<[CartItem]>(value: [])
    private let selectedSortOptionRelay = BehaviorRelay<CartSortOption>(value: .createdAtDesc)
    
    struct Input {
        /// 화면 로드 이벤트
        let viewDidLoad: Observable<Void>
        /// 화면 재진입 이벤트
        let viewWillAppear: Observable<Void>
        /// 장바구니 아이템 삭제 이벤트
        let itemDeleted: Observable<CartItem>
        /// 장바구니 아이템 수량 증가 이벤트
        let itemQuantityIncreased: Observable<CartItem>
        /// 장바구니 아이템 수량 감소 이벤트
        let itemQuantityDecreased: Observable<CartItem>
        /// 정렬 선택 이벤트
        let sortOptionSelected: Observable<CartSortOption>
    }
    
    struct Output {
        /// 장바구니 아이템 목록
        let cartItems: Observable<[CartItem]>
        /// 선택된 정렬 타이틀
        let selectedSortTitle: Observable<String>
    }
    
    func transform(_ input: Input) -> Output {
        input.viewDidLoad
            .subscribe(onNext: { [weak self] in
                self?.bindCartItems()
            })
            .disposed(by: disposeBag)

        input.viewWillAppear
            .subscribe(onNext: { [weak self] in
                self?.fetchCartItems()
            })
            .disposed(by: disposeBag)

        input.itemDeleted
            .subscribe(onNext: { [weak self] item in
                self?.deleteCartItem(item)
            })
            .disposed(by: disposeBag)

        input.itemQuantityIncreased
            .subscribe(onNext: { [weak self] item in
                self?.updateCartItem(id: item.id) {
                    $0.increased()
                }
            })
            .disposed(by: disposeBag)

        input.itemQuantityDecreased
            .subscribe(onNext: { [weak self] item in
                self?.updateCartItem(id: item.id) {
                    $0.decreased()
                }
            })
            .disposed(by: disposeBag)

        input.sortOptionSelected
            .subscribe(onNext: { [weak self] option in
                guard let self else { return }
                self.selectedSortOptionRelay.accept(option)
                self.applySortedItems(self.cartItemsRelay.value)
            })
            .disposed(by: disposeBag)
        
        return Output(
            cartItems: cartItemsRelay.asObservable(),
            selectedSortTitle: selectedSortOptionRelay
                .map { $0.rawValue }
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
        .subscribe(onNext: { [weak self] items in
            self?.applySortedItems(items)
        })
        .disposed(by: cartItemObservationDisposeBag)
    }

    /// 장바구니 아이템 갱신
    func updateCartItem(
        id: UUID,
        transform: (CartItem) -> CartItem
    ) {
        var items = cartItemsRelay.value

        guard let index = items.firstIndex(where: { $0.id == id }) else {
            return
        }

        let updatedItem = transform(items[index])
        items[index] = updatedItem
        applySortedItems(items)

        do {
            try coreDataManager.updateCartItem(updatedItem.toPayload)
        } catch {
            return
        }
    }

    /// 장바구니 아이템 삭제
    func deleteCartItem(_ item: CartItem) {
        do {
            try coreDataManager.deleteCartItem(id: item.id)

            let items = cartItemsRelay.value.filter {
                $0.id != item.id
            }
            applySortedItems(items)
        } catch {
            return
        }
    }

    /// 장바구니 목록 재조회
    func fetchCartItems() {
        do {
            let items = try coreDataManager.fetchAllCartItems()
            applySortedItems(items.map { $0.toDomain() })
        } catch {
            return
        }
    }

    /// 정렬 적용
    func applySortedItems(_ items: [CartItem]) {
        cartItemsRelay.accept(sortItems(items))
    }

    /// 장바구니 아이템 정렬
    func sortItems(_ items: [CartItem]) -> [CartItem] {
        switch selectedSortOptionRelay.value {
        case .nameAsc:
            return items.sorted {
                $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
        case .nameDesc:
            return items.sorted {
                $0.name.localizedStandardCompare($1.name) == .orderedDescending
            }
        case .createdAtDesc:
            return items.sorted {
                ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast)
            }
        case .createdAtAsc:
            return items.sorted {
                ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast)
            }
        case .quantityDesc:
            return items.sorted { $0.quantity > $1.quantity }
        case .quantityAsc:
            return items.sorted { $0.quantity < $1.quantity }
        }
    }
}
