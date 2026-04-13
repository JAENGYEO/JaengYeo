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
}

final class StockViewModel:  NSObject, ViewModelProtocol {
    
    private let disposeBag = DisposeBag()
    
    private let coreDataManager: CoreDataManagerProtocol
    
    private var productFetchResultController: NSFetchedResultsController<ProductEntity>?
    private var midCategoryFetchResultContoller: NSFetchedResultsController<MidCategoryEntity>?
    private var subCategoryFetchResultContoller: NSFetchedResultsController<SubCategoryEntity>?
    
    /// 메인 카테고리 목록
    var mainCategory = BehaviorRelay<[String]>(value:
                                                [MainCategory.foodstuff.rawValue, MainCategory.household.rawValue])
    /// 상품 목록
    private let productsRelay = BehaviorRelay<[ProductCellItem]>(value: [])
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
    /// 선택된 상품 정렬
    private let selectedSortOptionRelay = BehaviorRelay<ProductSortOption>(value: .createdAtDesc)

    struct Input {
        let viewDidLoad: Observable<Void>
        let mainCategorySelected: Observable<Int>
        let midCategoryTapped: Observable<Void>
        let subCategoryTapped: Observable<Void>
        let midCategoryApplied: Observable<[String]>
        let subCategoryApplied: Observable<[String]>
        let sortOptionSelected: Observable<ProductSortOption>
    }
    
    struct Output {
        let mainCategories: Observable<[String]>
        let products: Observable<[ProductCellItem]>
        let presentMidCategoryItems: Observable<[CategorySelectionItem]>
        let presentSubCategoryItems: Observable<[CategorySelectionItem]>
        let selectedSortTitle: Observable<String>
        let isMidCategorySelected: Observable<Bool>
        let isSubCategorySelected: Observable<Bool>
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
                self.configureProductResultController()
                self.configureMidCategoryResultController()
                self.configureSubCategoryResultController()
                self.updatePredicate(for: 0)
            })
            .disposed(by: disposeBag)
        
        /// 메인 카테고리 선택
        input.mainCategorySelected
            .subscribe(onNext: { [weak self] page in
                guard let self else { return }
                self.resetCategoryFilters()
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
                self.selectedMidCategoryIDsRelay.accept(Set(ids))
                self.updatePredicate()
            })
            .disposed(by: disposeBag)
        
        /// 소분류 필터 적용
        input.subCategoryApplied
            .subscribe(onNext: { [weak self] ids in
                guard let self else { return }
                self.selectedSubCategoryIDsRelay.accept(Set(ids))
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
            totalCountText: totalCountText
        )
    }
    
    init(coreDataManager: CoreDataManagerProtocol) {
        self.coreDataManager = coreDataManager
        super.init()
    }
}

//MARK: - Core Data
extension StockViewModel: NSFetchedResultsControllerDelegate {
    /// 상품 조회 컨트롤러 구성
    private func configureProductResultController() {
        let request = ProductEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: ProductEntity.Keys.createdAt, ascending: false)
        ]
        request.predicate = NSPredicate(format: "mainCategory == %@", MainCategory.foodstuff.rawValue)

        let controller = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: coreDataManager.context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        controller.delegate = self
        productFetchResultController = controller
    }
    
    /// 중분류 조회 컨트롤러 구성
    private func configureMidCategoryResultController() {
        let request = MidCategoryEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: MidCategoryEntity.Keys.sortOrder, ascending: true)
        ]

        let controller = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: coreDataManager.context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        controller.delegate = self
        midCategoryFetchResultContoller = controller
    }
    
    /// 소분류 조회 컨트롤러 구성
    private func configureSubCategoryResultController() {
        let request = SubCategoryEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: SubCategoryEntity.Keys.sortOrder, ascending: true)
        ]

        let controller = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: coreDataManager.context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        controller.delegate = self
        subCategoryFetchResultContoller = controller
    }
    
    /// 데이터 조회
    private func performFetch() {
        do {
            try productFetchResultController?.performFetch()
            try midCategoryFetchResultContoller?.performFetch()
            try subCategoryFetchResultContoller?.performFetch()
            updateProducts()
            updateMidCategories()
            updateSubCategories()
        } catch {
            
        }
    }
    
    /// 메인 카테고리 필터 적용
    private func updatePredicate(for selectedIndex: Int) {
        selectedMainCategoryIndexRelay.accept(selectedIndex)
        
        let mainCategoryPredicate = makeMainCategoryPredicate(for: selectedIndex)
        
        productFetchResultController?.fetchRequest.predicate = makeProductPredicate(
            mainCategoryPredicate: mainCategoryPredicate
        )
        midCategoryFetchResultContoller?.fetchRequest.predicate = mainCategoryPredicate
        subCategoryFetchResultContoller?.fetchRequest.predicate = mainCategoryPredicate

        performFetch()
    }
    
    /// 선택 필터 적용
    private func updatePredicate() {
        let mainCategoryPredicate = makeMainCategoryPredicate(
            for: selectedMainCategoryIndexRelay.value
        )

        productFetchResultController?.fetchRequest.predicate = makeProductPredicate(
            mainCategoryPredicate: mainCategoryPredicate
        )

        performFetch()
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
    
    /// 선택 필터 초기화
    private func resetCategoryFilters() {
        selectedMidCategoryIDsRelay.accept([])
        selectedSubCategoryIDsRelay.accept([])
    }
    
    /// 상품 도메인 변환 및 반영
    private func updateProducts() {
        let midCategoryNames = midCategoryFetchResultContoller?.fetchedObjects?
            .reduce(into: [UUID: String]()) {
                $0[$1.id] = $1.name
            } ?? [:]
        
        let subCategoryNames = subCategoryFetchResultContoller?.fetchedObjects?
            .reduce(into: [UUID: String]()) {
                $0[$1.id] = $1.name
            } ?? [:]
        
        let products = productFetchResultController?.fetchedObjects?
            .map { $0.toDomain }
            .map {
                ProductCellItem(
                    product: $0,
                    midCategory: $0.midCategoryId.flatMap { midCategoryNames[$0] },
                    subCategory: $0.subCategoryId.flatMap { subCategoryNames[$0] }
                )
            } ?? []

        productsRelay.accept(sortProducts(products))
    }
    
    /// 중분류 아이템 변환 및 반영
    private func updateMidCategories() {
        let categories = midCategoryFetchResultContoller?.fetchedObjects?
            .map {
                CategorySelectionItem(
                    id: $0.id.uuidString,
                    title: $0.name,
                    image: UIImage(named: $0.iconName ?? "Category"),
                    isSelect: selectedMidCategoryIDsRelay.value.contains($0.id.uuidString)
                )
            } ?? []

        midCategoriesRelay.accept(categories)
    }
    
    /// 소분류 아이템 변환 및 반영
    private func updateSubCategories() {
        let categories = subCategoryFetchResultContoller?.fetchedObjects?
            .map {
                CategorySelectionItem(
                    id: $0.id.uuidString,
                    title: $0.name,
                    image: UIImage(named: $0.iconName ?? "Category"),
                    isSelect: selectedSubCategoryIDsRelay.value.contains($0.id.uuidString)
                )
            } ?? []

        subCategoriesRelay.accept(categories)
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if controller == productFetchResultController {
            updateProducts()
        }
        
        if controller == midCategoryFetchResultContoller {
            updateMidCategories()
        }
        
        if controller == subCategoryFetchResultContoller {
            updateSubCategories()
        }
    }
}

//MARK: - Sort
private extension StockViewModel {
    /// 상품 정렬
    func sortProducts(_ products: [ProductCellItem]) -> [ProductCellItem] {
        switch selectedSortOptionRelay.value {
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
            return products.sorted { $0.product.quantity > $1.product.quantity }
        case .quantityAsc:
            return products.sorted { $0.product.quantity < $1.product.quantity }
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
