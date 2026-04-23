//
//  StockSearchViewModel.swift
//  JaengYeo
//
//  Created by Codex on 4/15/26.
//

import CoreData
import Foundation
import RxRelay
import RxSwift
import UIKit

final class StockSearchViewModel: NSObject, ViewModelProtocol {

    //MARK: - Properties
    private let disposeBag = DisposeBag()
    private let coreDataManager: CoreDataManagerProtocol
    private var productObservationDisposeBag = DisposeBag()
    private var midCategoryObservationDisposeBag = DisposeBag()
    private var subCategoryObservationDisposeBag = DisposeBag()

    /// 검색 결과 상품 목록
    private let productsRelay = BehaviorRelay<[ProductCellItem]>(value: [])
    /// 최근 검색어 목록
    private let recentSearchesRelay = BehaviorRelay<[RecentSearchPayload]>(value: [])
    /// 검색 대상 상품 엔티티 목록
    private let productEntitiesRelay = BehaviorRelay<[ProductEntity]>(value: [])
    /// 마지막 검색어
    private let latestKeywordRelay = BehaviorRelay<String>(value: "")

    /// 중분류 이름 매핑
    private var midCategoryNames: [UUID: String] = [:]
    /// 소분류 이름 매핑
    private var subCategoryNames: [UUID: String] = [:]
    /// 소분류 이미지 매핑
    private var subCategoryImages: [UUID: UIImage] = [:]

    //MARK: - React Binding
    struct Input {
        /// 화면 진입 이벤트
        let viewDidLoad: Observable<Void>
        /// 검색어 입력 이벤트
        let searchText: Observable<String>
        /// 검색 버튼 선택 이벤트
        let searchButtonTapped: Observable<String>
        /// 최근 검색어 개별 삭제 이벤트
        let deleteRecentSearch: Observable<UUID>
        /// 최근 검색어 전체 삭제 이벤트
        let deleteAllRecentSearch: Observable<Void>
    }

    struct Output {
        /// 검색 결과 상품 목록
        let products: Observable<[ProductCellItem]>
        /// 최근 검색어 목록
        let recentSearches: Observable<[RecentSearchPayload]>
    }

    func transform(_ input: Input) -> Output {
        input.viewDidLoad
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                self.bindProducts()
                self.bindMidCategories()
                self.bindSubCategories()
                self.loadRecentSearches()
            })
            .disposed(by: disposeBag)

        input.searchText
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] text in
                self?.latestKeywordRelay.accept(text)
                self?.updateProducts(keyword: text)
            })
            .disposed(by: disposeBag)

        input.searchButtonTapped
            .subscribe(onNext: { [weak self] keyword in
                guard let self else { return }
                try? self.coreDataManager.saveRecentSearch(keyword: keyword)
                self.loadRecentSearches()
            })
            .disposed(by: disposeBag)

        input.deleteRecentSearch
            .subscribe(onNext: { [weak self] id in
                guard let self else { return }
                try? self.coreDataManager.deleteRecentSearch(id: id)
                self.loadRecentSearches()
            })
            .disposed(by: disposeBag)

        input.deleteAllRecentSearch
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                try? self.coreDataManager.deleteAllRecentSearches()
                self.loadRecentSearches()
            })
            .disposed(by: disposeBag)

        return Output(
            products: productsRelay.asObservable(),
            recentSearches: recentSearchesRelay.asObservable()
        )
    }

    //MARK: - Init
    init(coreDataManager: CoreDataManagerProtocol) {
        self.coreDataManager = coreDataManager
        super.init()
    }
}

//MARK: - CoreData Stream
private extension StockSearchViewModel {
    /// 상품 조회 스트림 바인딩
    func bindProducts() {
        productObservationDisposeBag = DisposeBag()

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
            self.productEntitiesRelay.accept(products)
            self.updateProducts(keyword: self.latestKeywordRelay.value)
        })
        .disposed(by: productObservationDisposeBag)
    }

    /// 중분류 조회 스트림 바인딩
    func bindMidCategories() {
        midCategoryObservationDisposeBag = DisposeBag()

        coreDataManager.observeMidCategories(
            predicate: nil,
            sortDescriptors: [
                NSSortDescriptor(
                    key: MidCategoryEntity.Keys.sortOrder,
                    ascending: true
                )
            ]
        )
        .subscribe(onNext: { [weak self] categories in
            guard let self else { return }
            self.midCategoryNames = categories.reduce(into: [UUID: String]()) {
                $0[$1.id] = $1.name
            }
            self.updateProducts(keyword: self.latestKeywordRelay.value)
        })
        .disposed(by: midCategoryObservationDisposeBag)
    }

    /// 소분류 조회 스트림 바인딩
    func bindSubCategories() {
        subCategoryObservationDisposeBag = DisposeBag()

        coreDataManager.observeSubCategories(
            predicate: nil,
            sortDescriptors: [
                NSSortDescriptor(
                    key: SubCategoryEntity.Keys.sortOrder,
                    ascending: true
                )
            ]
        )
        .subscribe(onNext: { [weak self] categories in
            guard let self else { return }

            self.subCategoryNames = categories.reduce(into: [UUID: String]()) {
                $0[$1.id] = $1.name
            }

            self.subCategoryImages = categories.reduce(into: [UUID: UIImage]()) {
                guard let iconName = $1.iconName,
                      let image = UIImage(named: iconName)
                else { return }
                $0[$1.id] = image
            }

            self.updateProducts(keyword: self.latestKeywordRelay.value)
        })
        .disposed(by: subCategoryObservationDisposeBag)
    }

    /// 최근 검색어 조회
    func loadRecentSearches() {
        let searches = (try? coreDataManager.fetchRecentSearches(limit: 10)) ?? []
        recentSearchesRelay.accept(searches)
    }
}

//MARK: - Update Products
private extension StockSearchViewModel {
    /// 검색어 기준 상품 목록 갱신
    func updateProducts(keyword: String) {
        let trimmedKeyword = keyword.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedKeyword.isEmpty else {
            productsRelay.accept([])
            return
        }

        let normalizedKeyword = normalizedSearchText(trimmedKeyword)

        let products: [ProductCellItem] = productEntitiesRelay.value
            .compactMap { [weak self] entity -> (priority: Int, item: ProductCellItem)? in
                guard let self else { return nil }

                let product = entity.toDomain
                let midCategoryName = product.midCategoryId.flatMap {
                    self.midCategoryNames[$0]
                }
                let subCategoryName = product.subCategoryId.flatMap {
                    self.subCategoryNames[$0]
                }
                let subCategoryImage = product.subCategoryId.flatMap {
                    self.subCategoryImages[$0]
                }

                let normalizedName = normalizedSearchText(product.name)
                let normalizedMid = midCategoryName.map {
                    self.normalizedSearchText($0)
                }
                let normalizedSub = subCategoryName.map {
                    self.normalizedSearchText($0)
                }

                let nameMatch = normalizedName.contains(normalizedKeyword)
                let midMatch = normalizedMid?.contains(normalizedKeyword) ?? false
                let subMatch = normalizedSub?.contains(normalizedKeyword) ?? false

                let priority: Int?
                if nameMatch {
                    priority = 0
                } else if midMatch {
                    priority = 1
                } else if subMatch {
                    priority = 2
                } else {
                    priority = nil
                }

                guard let priority else { return nil }

                let item = ProductCellItem(
                    product: product,
                    midCategory: midCategoryName,
                    subCategory: subCategoryName,
                    subCategoryImage: subCategoryImage
                )

                return (priority, item)
            }
            .sorted {
                if $0.priority != $1.priority {
                    return $0.priority < $1.priority
                }

                return $0.item.product.createdAt > $1.item.product.createdAt
            }
            .map { $0.item }

        productsRelay.accept(products)
    }
}

//MARK: - Normalized Text
private extension StockSearchViewModel {
    /// 문자열 정규화
    func normalizedSearchText(_ text: String) -> String {
        text
            .components(separatedBy: .whitespacesAndNewlines)
            .joined()
            .lowercased()
    }
}
