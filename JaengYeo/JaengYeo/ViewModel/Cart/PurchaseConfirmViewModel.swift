//
//  PurchaseConfirmViewModel.swift
//  JaengYeo
//
//  Created by Hanjuheon on 5/3/26.
//

import Foundation
import RxSwift
import RxRelay

final class PurchaseConfirmViewModel: ViewModelProtocol {

    //MARK: - Properties
    private let disposeBag = DisposeBag()
    private let coreDataManager: CoreDataManagerProtocol
    private let authManager: AuthManagerProtocol

    /// 화면 진입 시 원본 장바구니 아이템 목록 (수량 차감 기준)
    private let originalCartItems: [CartItem]
    /// 수량이 조정된 장바구니 아이템 목록
    private let cartItemsRelay: BehaviorRelay<[CartItem]>
    /// 선택된 아이템 ID 집합
    private let selectedIDsRelay: BehaviorRelay<Set<UUID>>
    /// 선택된 정렬
    private let selectedSortOptionRelay = BehaviorRelay<CartSortOption>(value: .createdAtDesc)

    //MARK: - Input / Output
    struct Input {
        /// 전체 선택/해제 탭 이벤트
        let selectAllTapped: Observable<Void>
        /// 개별 아이템 체크 탭 이벤트
        let itemCheckTapped: Observable<CartItem>
        /// 수량 추가 이벤트
        let itemQuantityIncreased: Observable<CartItem>
        /// 수량 차감 이벤트
        let itemQuantityDecreased: Observable<CartItem>
        /// 재고 등록하기 버튼 탭 이벤트
        let confirmTapped: Observable<Void>
        /// 정렬 선택 이벤트
        let sortOptionSelected: Observable<CartSortOption>
    }

    struct Output {
        /// 화면에 표시할 아이템 목록
        let items: Observable<[PurchaseConfirmItem]>
        /// 재고 등록 성공 이벤트
        let registerSuccess: Observable<Void>
        /// 재고 등록 실패 메시지
        let registerFailure: Observable<String>
        /// 선택된 정렬 타이틀
        let selectedSortTitle: Observable<String>
    }

    //MARK: - Init
    init(
        cartItems: [CartItem],
        coreDataManager: CoreDataManagerProtocol,
        authManager: AuthManagerProtocol
    ) {
        self.coreDataManager = coreDataManager
        self.authManager = authManager
        self.originalCartItems = cartItems
        self.cartItemsRelay = BehaviorRelay(value: cartItems)
        self.selectedIDsRelay = BehaviorRelay(
            value: Set(cartItems.map { $0.id })
        )
    }

    func transform(_ input: Input) -> Output {
        let registerSuccessSubject = PublishSubject<Void>()
        let registerFailureSubject = PublishSubject<String>()

        input.selectAllTapped
            .withLatestFrom(
                Observable.combineLatest(cartItemsRelay, selectedIDsRelay)
            )
            .subscribe(onNext: { [weak self] items, selectedIDs in
                guard let self else { return }
                let allSelected = selectedIDs.count == items.count
                if allSelected {
                    self.selectedIDsRelay.accept([])
                } else {
                    self.selectedIDsRelay.accept(Set(items.map { $0.id }))
                }
            })
            .disposed(by: disposeBag)

        input.itemCheckTapped
            .withLatestFrom(selectedIDsRelay) { item, selectedIDs in
                (item, selectedIDs)
            }
            .subscribe(onNext: { [weak self] item, selectedIDs in
                guard let self else { return }
                var updated = selectedIDs
                if updated.contains(item.id) {
                    updated.remove(item.id)
                } else {
                    updated.insert(item.id)
                }
                self.selectedIDsRelay.accept(updated)
            })
            .disposed(by: disposeBag)

        input.itemQuantityIncreased
            .subscribe(onNext: { [weak self] item in
                self?.updateQuantity(id: item.id) { $0.increased() }
            })
            .disposed(by: disposeBag)

        input.itemQuantityDecreased
            .subscribe(onNext: { [weak self] item in
                self?.updateQuantity(id: item.id) { $0.decreased() }
            })
            .disposed(by: disposeBag)

        input.confirmTapped
            .withLatestFrom(
                Observable.combineLatest(cartItemsRelay, selectedIDsRelay)
            )
            .subscribe(onNext: { [weak self] items, selectedIDs in
                guard let self else { return }
                let selectedItems = items.filter { selectedIDs.contains($0.id) }
                guard !selectedItems.isEmpty else {
                    registerFailureSubject.onNext("상품을 하나 이상 선택해주세요.")
                    return
                }
                self.registerItems(
                    selectedItems,
                    successSubject: registerSuccessSubject,
                    failureSubject: registerFailureSubject
                )
            })
            .disposed(by: disposeBag)

        input.sortOptionSelected
            .bind(to: selectedSortOptionRelay)
            .disposed(by: disposeBag)

        let items = Observable.combineLatest(
            cartItemsRelay,
            selectedIDsRelay,
            selectedSortOptionRelay
        )
            .map { items, selectedIDs, sortOption -> [PurchaseConfirmItem] in
                Self.sortItems(items, option: sortOption).map {
                    PurchaseConfirmItem(
                        cartItem: $0,
                        isSelected: selectedIDs.contains($0.id)
                    )
                }
            }

        return Output(
            items: items,
            registerSuccess: registerSuccessSubject.asObservable(),
            registerFailure: registerFailureSubject.asObservable(),
            selectedSortTitle: selectedSortOptionRelay
                .map { $0.rawValue }
                .asObservable()
        )
    }
}

//MARK: - Sort
private extension PurchaseConfirmViewModel {
    static func sortItems(
        _ items: [CartItem],
        option: CartSortOption
    ) -> [CartItem] {
        switch option {
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

//MARK: - Quantity
private extension PurchaseConfirmViewModel {
    func updateQuantity(id: UUID, transform: (CartItem) -> CartItem) {
        var items = cartItemsRelay.value
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index] = transform(items[index])
        cartItemsRelay.accept(items)
    }
}

//MARK: - Register
private extension PurchaseConfirmViewModel {
    func registerItems(
        _ items: [CartItem],
        successSubject: PublishSubject<Void>,
        failureSubject: PublishSubject<String>
    ) {
        guard let userId = authManager.currentUserId else {
            failureSubject.onNext("로그인이 필요합니다.")
            return
        }

        do {
            for item in items {
                if let referenceId = item.referenceId {
                    let isFoodstuff = item.mainCategory == MainCategory.foodstuff.rawValue
                    if isFoodstuff {
                        /// 식재료: 기존 상품 정보를 복사해 새 상품으로 등록
                        try copyProductAsNew(referenceId: referenceId, quantity: item.quantity, userId: userId)
                    } else {
                        /// 생활용품: 기존 상품 수량 합산
                        try increaseExistingProduct(referenceId: referenceId, quantity: item.quantity)
                    }
                } else {
                    try createNewProduct(from: item, userId: userId)
                }
                let originalQuantity = originalCartItems.first(where: { $0.id == item.id })?.quantity ?? item.quantity
                let remaining = originalQuantity - item.quantity
                if remaining > 0 {
                    /// 등록 수량이 원본보다 적으면 차감 후 잔여 수량으로 업데이트
                    let updatedItem = CartItem(
                        id: item.id,
                        referenceId: item.referenceId,
                        name: item.name,
                        mainCategory: item.mainCategory,
                        quantity: remaining,
                        createdAt: item.createdAt
                    )
                    try coreDataManager.updateCartItem(updatedItem.toPayload)
                } else {
                    try coreDataManager.deleteCartItem(id: item.id)
                }
            }
            successSubject.onNext(())
        } catch {
            failureSubject.onNext("재고 등록 중 오류가 발생했습니다.")
        }
    }

    /// 식재료: 기존 상품 정보를 복사해 새 UUID로 상품 생성
    func copyProductAsNew(referenceId: UUID, quantity: Int, userId: UUID) throws {
        let ref = try coreDataManager.fetchProduct(of: referenceId)
        let now = Date()

        /// 기존 구매일 대비 소비기한 간격을 계산해 새 구매일에 동일하게 적용
        let newExpiryDate: Date? = {
            guard
                let refPurchaseDate = ref.purchaseDate,
                let refExpiryDate = ref.expiryDate
            else { return nil }
            let shelfLife = refExpiryDate.timeIntervalSince(refPurchaseDate)
            return now.addingTimeInterval(shelfLife)
        }()

        let payload = ProductPayload(
            id: UUID(),
            userId: userId,
            name: ref.name,
            quantity: Int32(quantity),
            quantityUnit: ref.quantityUnit,
            mainCategory: ref.mainCategory,
            midCategoryId: ref.midCategoryId,
            subCategoryId: ref.subCategoryId,
            purchaseDate: now,
            expiryDate: newExpiryDate,
            price: 0,
            locationMemo: nil,
            memo: nil,
            imageUrl: ref.imageUrl,
            isClassified: ref.isClassified,
            lowStockThreshold: ref.lowStockThreshold,
            isFavorite: false,
            createdAt: now,
            updatedAt: now,
            syncStatus: SyncStatus.pendingUpload.rawValue,
            isLowStockNotificationEnabled: false,
            caution: nil,
            brand: ref.brand
        )
        try coreDataManager.createProduct(payload)
    }

    /// 생활용품: 기존 상품 수량 합산
    func increaseExistingProduct(referenceId: UUID, quantity: Int) throws {
        let ref = try coreDataManager.fetchProduct(of: referenceId)
        let updatedQuantity = min(
            Int(ref.quantity) + quantity,
            CartItem.maxQuantity
        )

        let payload = ProductPayload(
            id: ref.id,
            userId: ref.userId,
            name: ref.name,
            quantity: Int32(updatedQuantity),
            quantityUnit: ref.quantityUnit,
            mainCategory: ref.mainCategory,
            midCategoryId: ref.midCategoryId,
            subCategoryId: ref.subCategoryId,
            purchaseDate: ref.purchaseDate,
            expiryDate: ref.expiryDate,
            price: ref.price,
            locationMemo: ref.locationMemo,
            memo: ref.memo,
            imageUrl: ref.imageUrl,
            isClassified: ref.isClassified,
            lowStockThreshold: ref.lowStockThreshold,
            isFavorite: ref.isFavorite,
            createdAt: ref.createdAt,
            updatedAt: Date(),
            syncStatus: SyncStatus.pendingUpload.rawValue,
            isLowStockNotificationEnabled: ref.isLowStockNotificationEnabled,
            caution: ref.caution,
            brand: ref.brand
        )
        try coreDataManager.updateProduct(payload)
    }

    /// 신규 상품 생성
    func createNewProduct(from item: CartItem, userId: UUID) throws {
        let now = Date()
        let payload = ProductPayload(
            id: UUID(),
            userId: userId,
            name: item.name,
            quantity: Int32(item.quantity),
            quantityUnit: nil,
            mainCategory: item.mainCategory,
            midCategoryId: nil,
            subCategoryId: nil,
            purchaseDate: now,
            expiryDate: nil,
            price: 0,
            locationMemo: nil,
            memo: nil,
            imageUrl: nil,
            isClassified: false,
            lowStockThreshold: nil,
            isFavorite: false,
            createdAt: now,
            updatedAt: now,
            syncStatus: SyncStatus.pendingUpload.rawValue,
            isLowStockNotificationEnabled: false,
            caution: nil,
            brand: nil
        )
        try coreDataManager.createProduct(payload)
    }
}
