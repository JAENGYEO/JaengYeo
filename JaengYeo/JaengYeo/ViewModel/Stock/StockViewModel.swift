//
//  StockViewModel.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/9/26.
//

import Foundation
import CoreData
import RxSwift
import RxRelay
import UIKit

//MARK: - Enum
enum MainCategory: String {
    case foodstuff = "식재료"
    case household = "생활용품"
}

//MARK: - Sort
enum ProductSortOption: String, CaseIterable {
    case nameAtAsc = "이름순"
    case nameAtDesc = "이름 역순"
    case createdAtDesc = "등록일 최신순"
    case createdAtAsc = "등록일 오래된순"
    case expiryDateAsc = "소비기한 가까운순"
    case expiryDateDesc = "소비기한 먼순"
    case quantityDesc = "재고 많은순"
    case quantityAsc = "재고 적은순"
}

struct ProductCellItem: Hashable {
    let product: Product
    let midCategory: String?
    let subCategory: String?
    let subCategoryImage: UIImage?
    let groupedCount: Int
    let totalQuantity: Int
    let groupedItems: [ProductCellItem]

    init(
        product: Product,
        midCategory: String?,
        subCategory: String?,
        subCategoryImage: UIImage? = nil,
        groupedCount: Int = 1,
        totalQuantity: Int? = nil,
        groupedItems: [ProductCellItem] = []
    ) {
        self.product = product
        self.midCategory = midCategory
        self.subCategory = subCategory
        self.subCategoryImage = subCategoryImage
        self.groupedCount = groupedCount
        self.totalQuantity = totalQuantity ?? product.quantity
        self.groupedItems = groupedItems
    }

    var displayTitle: String {
        if isGrouped {
            return "\(product.name) (\(groupedCount)건)"
        }
        
        return product.name
    }
    
    var isGrouped: Bool {
        groupedCount > 1
    }
}

final class StockViewModel:  NSObject, ViewModelProtocol {
    
    private let disposeBag = DisposeBag()
    
    private let coreDataManager: CoreDataManagerProtocol
    private var allProductObservationDisposeBag = DisposeBag()
    private var productObservationDisposeBag = DisposeBag()
    private var midCategoryObservationDisposeBag = DisposeBag()
    private var subCategoryObservationDisposeBag = DisposeBag()
    
    /// 메인 카테고리 목록
    var mainCategory = BehaviorRelay<[String]>(value:
                                                [MainCategory.foodstuff.rawValue, MainCategory.household.rawValue])
    /// 상품 목록
    private let productsRelay = BehaviorRelay<[ProductCellItem]>(value: [])
    /// 전체 상품 존재 여부
    private let hasAnyProductRelay = BehaviorRelay<Bool>(value: false)
    /// 상품 엔티티 목록
    private let productEntitiesRelay = BehaviorRelay<[ProductEntity]>(value: [])
    /// 전체 상품 엔티티 목록
    private let allProductEntitiesRelay = BehaviorRelay<[ProductEntity]>(value: [])
    /// 중분류 엔티티 목록
    private let midCategoryEntitiesRelay = BehaviorRelay<[MidCategoryEntity]>(value: [])
    /// 소분류 엔티티 목록
    private let subCategoryEntitiesRelay = BehaviorRelay<[SubCategoryEntity]>(value: [])
    /// 중분류 목록
    private let midCategoriesRelay = BehaviorRelay<[CategorySelectionItem]>(value: [])
    /// 소분류 목록
    private let subCategoriesRelay = BehaviorRelay<[CategorySelectionItem]>(value: [])
    /// 선택된 중분류 ID
    private let selectedMidCategoryIDsRelay = BehaviorRelay<Set<String>>(value: [])
    /// 선택된 소분류 ID
    private let selectedSubCategoryIDsRelay = BehaviorRelay<Set<String>>(value: [])
    /// 선택된 메인 카테고리 인덱스
    private let selectedMainCategoryIndexRelay = BehaviorRelay<Int>(value: 0)
    /// 대분류별 선택된 중분류 ID
    private var selectedMidCategoryIDsByMainCategory = [Int: Set<String>]()
    /// 대분류별 선택된 소분류 ID
    private var selectedSubCategoryIDsByMainCategory = [Int: Set<String>]()
    /// 선택된 상품 정렬
    private let selectedSortOptionRelay = BehaviorRelay<ProductSortOption>(value: .createdAtDesc)

    struct Input {
        /// 화면 로드 이벤트
        let viewDidLoad: Observable<Void>
        /// 대분류 선택 이벤트
        let mainCategorySelected: Observable<Int>
        /// 중분류 버튼 선택 이벤트
        let midCategoryTapped: Observable<Void>
        /// 소분류 버튼 선택 이벤트
        let subCategoryTapped: Observable<Void>
        /// 중분류 적용 이벤트
        let midCategoryApplied: Observable<[String]>
        /// 소분류 적용 이벤트
        let subCategoryApplied: Observable<[String]>
        /// 상품 정렬 선택 이벤트
        let sortOptionSelected: Observable<ProductSortOption>
        /// 상품 재고 증가 이벤트
        let productQuantityIncreased: Observable<Product>
        /// 상품 재고 차감 이벤트
        let productQuantityDecreased: Observable<Product>
        /// 상품 삭제 이벤트
        let productDeleted: Observable<[UUID]>
    }
    
    struct Output {
        /// 대분류 목록
        let mainCategories: Observable<[String]>
        /// 상품 목록
        let products: Observable<[ProductCellItem]>
        /// 중분류 아이템
        let presentMidCategoryItems: Observable<[CategorySelectionItem]>
        /// 소분류 아이템
        let presentSubCategoryItems: Observable<[CategorySelectionItem]>
        /// 선택 정렬 타이틀
        let selectedSortTitle: Observable<String>
        /// 중분류 선택 여부
        let isMidCategorySelected: Observable<Bool>
        /// 소분류 선택 여부
        let isSubCategorySelected: Observable<Bool>
        /// 전체 상품 존재 여부
        let hasAnyProduct: Observable<Bool>
        /// 상품 개수
        let totalCountText: Observable<Int>
    }
    
    func transform(_ input: Input) -> Output {
        /// 중분류 선택 모달 표시
        let presentMidCategoryItemsRelay = PublishRelay<[CategorySelectionItem]>()
        /// 소분류 선택 모달 표시
        let presentSubCategoryItemsRelay = PublishRelay<[CategorySelectionItem]>()
        
        /// 초기 데이터 조회
        input.viewDidLoad
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                self.bindAllProducts()
                self.updatePredicate(for: 0)
            })
            .disposed(by: disposeBag)
        
        /// 메인 카테고리 선택
        input.mainCategorySelected
            .subscribe(onNext: { [weak self] page in
                guard let self else { return }
                self.updatePredicate(for: page)
            })
            .disposed(by: disposeBag)
        
        /// 중분류 버튼 선택
        input.midCategoryTapped
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                presentMidCategoryItemsRelay.accept(self.midCategoriesRelay.value)
            })
            .disposed(by: disposeBag)
        
        /// 소분류 버튼 선택
        input.subCategoryTapped
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                presentSubCategoryItemsRelay.accept(self.subCategoriesRelay.value)
            })
            .disposed(by: disposeBag)
        
        /// 중분류 필터 적용
        input.midCategoryApplied
            .subscribe(onNext: { [weak self] ids in
                guard let self else { return }
                self.updateSelectedMidCategoryIDs(Set(ids))
                self.updatePredicate()
            })
            .disposed(by: disposeBag)
        
        /// 소분류 필터 적용
        input.subCategoryApplied
            .subscribe(onNext: { [weak self] ids in
                guard let self else { return }
                self.updateSelectedSubCategoryIDs(Set(ids))
                self.updatePredicate()
            })
            .disposed(by: disposeBag)
        
        /// 상품 정렬 선택
        input.sortOptionSelected
            .subscribe(onNext: { [weak self] sortOption in
                guard let self else { return }
                self.selectedSortOptionRelay.accept(sortOption)
                self.updateProducts()
            })
            .disposed(by: disposeBag)
        
        /// 상품 재고 증가
        input.productQuantityIncreased
            .subscribe(onNext: { [weak self] product in
                guard let self else { return }
                self.increaseProductQuantity(product)
                self.refreshProducts()
            })
            .disposed(by: disposeBag)
        
        /// 상품 재고 차감
        input.productQuantityDecreased
            .subscribe(onNext: { [weak self] product in
                guard let self else { return }
                self.decreaseProductQuantity(product)
                self.refreshProducts()
            })
            .disposed(by: disposeBag)
        
        /// 상품 삭제
        input.productDeleted
            .subscribe(onNext: { [weak self] productIDs in
                guard let self else { return }
                self.deleteProducts(productIDs)
                self.refreshProducts()
            })
            .disposed(by: disposeBag)
        
        /// 선택 정렬 타이틀
        let selectedSortTitle = selectedSortOptionRelay
            .map { $0.rawValue }
            .asObservable()
        
        /// 중분류 선택 여부
        let isMidCategorySelected = selectedMidCategoryIDsRelay
            .map { !$0.isEmpty }
            .asObservable()
        
        /// 소분류 선택 여부
        let isSubCategorySelected = selectedSubCategoryIDsRelay
            .map { !$0.isEmpty }
            .asObservable()
        
        /// 상품 개수
        let totalCountText = productsRelay
            .map { $0.count }
            .asObservable()
        
        return Output(
            mainCategories: mainCategory.asObservable(),
            products: productsRelay.asObservable(),
            presentMidCategoryItems: presentMidCategoryItemsRelay.asObservable(),
            presentSubCategoryItems: presentSubCategoryItemsRelay.asObservable(),
            selectedSortTitle: selectedSortTitle,
            isMidCategorySelected: isMidCategorySelected,
            isSubCategorySelected: isSubCategorySelected,
            hasAnyProduct: hasAnyProductRelay.asObservable(),
            totalCountText: totalCountText
        )
    }
    
    init(coreDataManager: CoreDataManagerProtocol) {
        self.coreDataManager = coreDataManager
        super.init()
    }
}

//MARK: - Core Data
private extension StockViewModel {
    /// 전체 상품 조회 스트림 바인딩
    func bindAllProducts() {
        allProductObservationDisposeBag = DisposeBag()

        coreDataManager.observeProducts(
            predicate: nil,
            sortDescriptors: [
                NSSortDescriptor(
                    key: ProductEntity.Keys.createdAt,
                    ascending: false
                )
            ]
        )
        .subscribe(onNext: { [weak self] products in
            guard let self else { return }
            self.allProductEntitiesRelay.accept(products)
            self.hasAnyProductRelay.accept(!products.isEmpty)
            self.updateMidCategories()
            self.updateSubCategories()
        })
        .disposed(by: allProductObservationDisposeBag)
    }

    /// 상품 조회 스트림 바인딩
    func bindProducts(predicate: NSPredicate?) {
        productObservationDisposeBag = DisposeBag()

        coreDataManager.observeProducts(
            predicate: predicate,
            sortDescriptors: [
                NSSortDescriptor(
                    key: ProductEntity.Keys.createdAt,
                    ascending: false
                )
            ]
        )
        .subscribe(onNext: { [weak self] products in
            guard let self else { return }
            self.productEntitiesRelay.accept(products)
            self.updateProducts()
        })
        .disposed(by: productObservationDisposeBag)
    }
    
    /// 중분류 조회 스트림 바인딩
    func bindMidCategories(predicate: NSPredicate?) {
        midCategoryObservationDisposeBag = DisposeBag()

        coreDataManager.observeMidCategories(
            predicate: predicate,
            sortDescriptors: [
                NSSortDescriptor(
                    key: MidCategoryEntity.Keys.sortOrder,
                    ascending: true
                )
            ]
        )
        .subscribe(onNext: { [weak self] categories in
            guard let self else { return }
            self.midCategoryEntitiesRelay.accept(categories)
            self.updateMidCategories()
            self.updateProducts()
        })
        .disposed(by: midCategoryObservationDisposeBag)
    }
    
    /// 소분류 조회 스트림 바인딩
    func bindSubCategories(predicate: NSPredicate?) {
        subCategoryObservationDisposeBag = DisposeBag()

        coreDataManager.observeSubCategories(
            predicate: predicate,
            sortDescriptors: [
                NSSortDescriptor(
                    key: SubCategoryEntity.Keys.sortOrder,
                    ascending: true
                )
            ]
        )
        .subscribe(onNext: { [weak self] categories in
            guard let self else { return }
            self.subCategoryEntitiesRelay.accept(categories)
            self.updateSubCategories()
            self.updateProducts()
        })
        .disposed(by: subCategoryObservationDisposeBag)
    }
    
    /// 메인 카테고리 필터 적용
    private func updatePredicate(for selectedIndex: Int) {
        selectedMainCategoryIndexRelay.accept(selectedIndex)
        restoreCategoryFilters(for: selectedIndex)
        
        let mainCategoryPredicate = makeMainCategoryPredicate(for: selectedIndex)
        
        bindProducts(
            predicate: makeProductPredicate(
                mainCategoryPredicate: mainCategoryPredicate
            )
        )
        bindMidCategories(predicate: mainCategoryPredicate)
        bindSubCategories(predicate: mainCategoryPredicate)
    }
    
    /// 선택 필터 적용
    private func updatePredicate() {
        let mainCategoryPredicate = makeMainCategoryPredicate(
            for: selectedMainCategoryIndexRelay.value
        )

        bindProducts(
            predicate: makeProductPredicate(
                mainCategoryPredicate: mainCategoryPredicate
            )
        )
    }

    /// 상품 목록 재조회
    private func refreshProducts() {
        bindAllProducts()
        updatePredicate()
    }
    
    /// 메인 카테고리 필터 조건 생성
    private func makeMainCategoryPredicate(for selectedIndex: Int) -> NSPredicate? {
        switch selectedIndex {
        case 0:
            return NSPredicate(format: "mainCategory == %@", MainCategory.foodstuff.rawValue)
        case 1:
            return NSPredicate(format: "mainCategory == %@", MainCategory.household.rawValue)
        default:
            return nil
        }
    }
    
    /// 상품 필터 조건 생성
    private func makeProductPredicate(
        mainCategoryPredicate: NSPredicate?
    ) -> NSPredicate? {
        var predicates = [NSPredicate]()
        
        if let mainCategoryPredicate {
            predicates.append(mainCategoryPredicate)
        }
        
        let midCategoryIDs = selectedMidCategoryIDsRelay.value.compactMap { UUID(uuidString: $0) }
        if !midCategoryIDs.isEmpty {
            predicates.append(NSPredicate(format: "midCategoryId IN %@", midCategoryIDs))
        }
        
        let subCategoryIDs = selectedSubCategoryIDsRelay.value.compactMap { UUID(uuidString: $0) }
        if !subCategoryIDs.isEmpty {
            predicates.append(NSPredicate(format: "subCategoryId IN %@", subCategoryIDs))
        }
        
        guard !predicates.isEmpty else { return nil }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
    
    /// 중분류 선택값 저장
    private func updateSelectedMidCategoryIDs(_ ids: Set<String>) {
        selectedMidCategoryIDsByMainCategory[
            selectedMainCategoryIndexRelay.value
        ] = ids
        selectedMidCategoryIDsRelay.accept(ids)
        updateMidCategories()
    }
    
    /// 소분류 선택값 저장
    private func updateSelectedSubCategoryIDs(_ ids: Set<String>) {
        selectedSubCategoryIDsByMainCategory[
            selectedMainCategoryIndexRelay.value
        ] = ids
        selectedSubCategoryIDsRelay.accept(ids)
        updateSubCategories()
    }
    
    /// 대분류별 선택값 복원
    private func restoreCategoryFilters(for selectedIndex: Int) {
        selectedMidCategoryIDsRelay.accept(
            selectedMidCategoryIDsByMainCategory[selectedIndex] ?? []
        )
        selectedSubCategoryIDsRelay.accept(
            selectedSubCategoryIDsByMainCategory[selectedIndex] ?? []
        )
        updateMidCategories()
        updateSubCategories()
    }
    
    /// 상품 도메인 변환 및 반영
    private func updateProducts() {
        let midCategoryNames = midCategoryEntitiesRelay.value
            .reduce(into: [UUID: String]()) {
                $0[$1.id] = $1.name
            }
        
        let subCategoryNames = subCategoryEntitiesRelay.value
            .reduce(into: [UUID: String]()) {
                $0[$1.id] = $1.name
            }
        
        let subCategoryImages = subCategoryEntitiesRelay.value
            .reduce(into: [UUID: UIImage]()) {
                guard let iconName = $1.iconName,
                      let image = UIImage(named: iconName)
                else { return }
                $0[$1.id] = image
            }
        
        let products = productEntitiesRelay.value
            .map { $0.toDomain }
            .map {
                ProductCellItem(
                    product: $0,
                    midCategory: $0.midCategoryId.flatMap { midCategoryNames[$0] },
                    subCategory: $0.subCategoryId.flatMap { subCategoryNames[$0] },
                    subCategoryImage: $0.subCategoryId.flatMap { subCategoryImages[$0] }
                )
            }

        productsRelay.accept(sortProducts(groupProducts(products)))
    }
    
    /// 중분류 아이템 변환 및 반영
    private func updateMidCategories() {
        let usedMidCategoryIDs = Set(
            allProductEntitiesRelay.value.compactMap { $0.midCategoryId }
        )

        let categories = midCategoryEntitiesRelay.value
            .map {
                CategorySelectionItem(
                    id: $0.id.uuidString,
                    title: $0.name,
                    image: UIImage(named: $0.iconName ?? "categoryIcon"),
                    isSelect: selectedMidCategoryIDsRelay.value.contains($0.id.uuidString),
                    isEnabled: usedMidCategoryIDs.contains($0.id)
                )
            }

        midCategoriesRelay.accept(categories)
    }
    
    /// 소분류 아이템 변환 및 반영
    private func updateSubCategories() {
        let usedSubCategoryIDs = Set(
            allProductEntitiesRelay.value.compactMap { $0.subCategoryId }
        )

        let categories = subCategoryEntitiesRelay.value
            .map {
                CategorySelectionItem(
                    id: $0.id.uuidString,
                    title: $0.name,
                    image: UIImage(named: $0.iconName ?? "categoryIcon"),
                    isSelect: selectedSubCategoryIDsRelay.value.contains($0.id.uuidString),
                    isEnabled: usedSubCategoryIDs.contains($0.id)
                )
            }

        subCategoriesRelay.accept(categories)
    }
}

//MARK: - Sort
private extension StockViewModel {
    /// 상품 정렬
    func sortProducts(_ products: [ProductCellItem]) -> [ProductCellItem] {
        switch selectedSortOptionRelay.value {
        case .nameAtDesc:
            return products.sorted { $0.product.name > $1.product.name }
        case .nameAtAsc:
            return products.sorted { $0.product.name < $1.product.name }
        case .createdAtDesc:
            return products.sorted { $0.product.createdAt > $1.product.createdAt }
        case .createdAtAsc:
            return products.sorted { $0.product.createdAt < $1.product.createdAt }
        case .expiryDateAsc:
            return products.sorted {
                compareOptionalDate(
                    $0.product.expiryDate,
                    $1.product.expiryDate,
                    ascending: true
                )
            }
        case .expiryDateDesc:
            return products.sorted {
                compareOptionalDate(
                    $0.product.expiryDate,
                    $1.product.expiryDate,
                    ascending: false
                )
            }
        case .quantityDesc:
            return products.sorted { $0.totalQuantity > $1.totalQuantity }
        case .quantityAsc:
            return products.sorted { $0.totalQuantity < $1.totalQuantity }
        }
    }
    
    /// 같은 이름 상품 묶기
    func groupProducts(_ products: [ProductCellItem]) -> [ProductCellItem] {
        let groupedProducts = Dictionary(grouping: products) {
            $0.product.name.trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
        }
        
        return groupedProducts.values.map { items in
            let sortedGroupItems = sortGroupItems(items)
            
            guard let representative = makeRepresentativeItem(from: sortedGroupItems) else {
                return items[0]
            }
            
            return ProductCellItem(
                product: representative.product,
                midCategory: representative.midCategory,
                subCategory: representative.subCategory,
                subCategoryImage: representative.subCategoryImage,
                groupedCount: items.count,
                totalQuantity: items.reduce(0) { $0 + $1.product.quantity },
                groupedItems: sortedGroupItems
            )
        }
    }
    
    /// 그룹 대표 상품 선택
    func makeRepresentativeItem(
        from items: [ProductCellItem]
    ) -> ProductCellItem? {
        let itemsWithExpiryDate = items.filter {
            $0.product.expiryDate != nil
        }
        
        if !itemsWithExpiryDate.isEmpty {
            return itemsWithExpiryDate.min {
                guard
                    let lhsDate = $0.product.expiryDate,
                    let rhsDate = $1.product.expiryDate
                else { return false }
                
                return lhsDate < rhsDate
            }
        }
        
        return items.max {
            $0.product.createdAt < $1.product.createdAt
        }
    }
    
    /// 그룹 내 상품 정렬
    func sortGroupItems(_ items: [ProductCellItem]) -> [ProductCellItem] {
        items.sorted {
            compareOptionalDate(
                $0.product.expiryDate,
                $1.product.expiryDate,
                ascending: true
            )
        }
    }
    
    /// Optional Date 정렬
    func compareOptionalDate(
        _ lhs: Date?,
        _ rhs: Date?,
        ascending: Bool
    ) -> Bool {
        switch (lhs, rhs) {
        case let (lhs?, rhs?):
            return ascending ? lhs < rhs : lhs > rhs
        case (.some, .none):
            return true
        case (.none, .some):
            return false
        case (.none, .none):
            return false
        }
    }
}


//MARK: - Delete
private extension StockViewModel {
    /// 상품 재고 1개 증가
    func increaseProductQuantity(_ product: Product) {
        do {
            try coreDataManager.updateProduct(
                product
                    .increasedQuantity()
                    .toPayload()
            )
        } catch {
        }
    }
    
    /// 상품 재고 1개 차감
    func decreaseProductQuantity(_ product: Product) {
        guard product.quantity > 0 else { return }
        
        do {
            try coreDataManager.updateProduct(
                product
                    .decreasedQuantity()
                    .toPayload()
            )
        } catch {
        }
    }

    /// 상품 삭제
    func deleteProducts(_ productIDs: [UUID]) {
        productIDs.forEach {
            try? coreDataManager.softDeleteProduct(id: $0)
        }
    }
}
