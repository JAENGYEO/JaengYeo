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

    /// 검색 결과로 보여줄 상품 셀 아이템 목록
    private let productsRelay = BehaviorRelay<[ProductCellItem]>(value: [])

    /// 마지막으로 입력된 검색어 저장
    private let latestKeywordRelay = BehaviorRelay<String>(value: "")

    /// 상품 변경 사항을 감지하기 위한 FetchedResultsController
    private var productFetchResultController: NSFetchedResultsController<ProductEntity>?

    /// 중분류 ID -> 이름 매핑 캐시
    private lazy var midCategoryNames: [UUID: String] = fetchMidCategoryNames()

    /// 소분류 ID -> 이름 매핑 캐시
    private lazy var subCategoryNames: [UUID: String] = fetchSubCategoryNames()
    
    /// 소분류 ID -> 이미지 매핑 캐시
    private lazy var subCategoryImages: [UUID: UIImage] = fetchSubCategoryImages()

    //MARK: - React Binding
    struct Input {
        /// 화면 진입 시점 이벤트
        let viewDidLoad: Observable<Void>

        /// 검색어 입력 이벤트
        let searchText: Observable<String>
    }

    struct Output {
        /// 검색 결과 상품 목록
        let products: Observable<[ProductCellItem]>
    }

    func transform(_ input: Input) -> Output {
        input.viewDidLoad
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                self.configureProductResultController()
                self.midCategoryNames = fetchMidCategoryNames()
                self.subCategoryNames = fetchSubCategoryNames()
                self.subCategoryImages = fetchSubCategoryImages()
                self.performFetch()
            })
            .disposed(by: disposeBag)

        input.searchText
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] text in
                /// 현재 검색어 저장
                self?.latestKeywordRelay.accept(text)

                /// 검색어 기준으로 결과 갱신
                self?.updateProduct(keyword: text)
            })
            .disposed(by: disposeBag)

        return Output(
            products: productsRelay.asObservable()
        )
    }

    //MARK: - Init
    init(coreDataManager: CoreDataManagerProtocol) {
        self.coreDataManager = coreDataManager
        super.init()
    }
}

//MARK: - FRC
extension StockSearchViewModel: NSFetchedResultsControllerDelegate {
    /// 상품 FRC 구성
    /// 여기서는 fetchRequest와 delegate만 연결하고,
    /// 실제 데이터 조회는 performFetch()에서 수행
    private func configureProductResultController() {
        let request = ProductEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(
                key: ProductEntity.Keys.createdAt,
                ascending: false
            )
        ]

        let controller = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: coreDataManager.context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        controller.delegate = self
        productFetchResultController = controller
    }

    /// 검색어 기준으로 상품 목록 갱신
    ///
    /// 우선순위:
    /// 1. 상품명(name)에 검색어 포함
    /// 2. 중분류명(midCategory)에 검색어 포함
    /// 3. 소분류명(subCategory)에 검색어 포함
    private func updateProduct(keyword: String) {
        let trimmedkeyword = keyword.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        /// 빈 검색어면 결과 비움
        guard !trimmedkeyword.isEmpty else {
            productsRelay.accept([])
            return
        }

        /// 공백 제거 + 소문자 변환한 검색어
        let normalizedKeyword = normalizedSearchText(trimmedkeyword)

        let products: [ProductCellItem] = productFetchResultController?
            .fetchedObjects?
            .compactMap { entity -> (priority: Int, item: ProductCellItem)? in
                let product = entity.toDomain

                /// 상품에 연결된 중분류/소분류 이름 조회
                let midCategoryName = product.midCategoryId.flatMap {
                    midCategoryNames[$0]
                }
                let subCategoryName = product.subCategoryId.flatMap {
                    subCategoryNames[$0]
                }
                let subCategoryImage = product.subCategoryId.flatMap {
                    subCategoryImages[$0]
                }

                /// 비교용 문자열 정규화
                let normalizedName = normalizedSearchText(product.name)
                let normalizedMid = midCategoryName.map {
                    normalizedSearchText($0)
                }
                let normalizedSub = subCategoryName.map {
                    normalizedSearchText($0)
                }

                /// 우선순위별 매칭 여부 확인
                let nameMatch = normalizedName.contains(normalizedKeyword)
                let midMatch =
                    normalizedMid?.contains(normalizedKeyword) ?? false
                let subMatch =
                    normalizedSub?.contains(normalizedKeyword) ?? false

                /// 매칭 우선순위 결정
                /// 상품명 > 중분류 > 소분류 순
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

                /// 어떤 조건에도 맞지 않으면 결과 제외
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
                /// 우선순위 오름차순 정렬
                if $0.priority !=  $1.priority {
                    return $0.priority < $1.priority
                }

                /// 같은 우선순위 내에서는 최신 등록순 정렬
                return $0.item.product.createdAt > $1.item.product.createdAt
            }
            .map { $0.item } ?? []

        productsRelay.accept(products)
    }

    /// fetch 수행
    private func performFetch() {
        do {
            try productFetchResultController?.performFetch()
        } catch {

        }
    }

    /// CoreData 변경 감지 시 호출
    /// 상세 화면에서 상품 수정 후 저장되면 여기로 들어올 수 있음
    func controllerDidChangeContent(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>
    ) {
        /// 카테고리 캐시 갱신
        self.midCategoryNames = fetchMidCategoryNames()
        self.subCategoryNames = fetchSubCategoryNames()
        self.subCategoryImages = fetchSubCategoryImages()

        /// 마지막 검색어 기준으로 다시 필터링
        updateProduct(keyword: latestKeywordRelay.value)
    }
}

//MARK: - Action
extension StockSearchViewModel {
    /// 문자열 정규화
    private func normalizedSearchText(_ text: String) -> String {
        text
            .components(separatedBy: .whitespacesAndNewlines)
            .joined()
            .lowercased()
    }
}

//MARK: - CoreData
extension StockSearchViewModel {
    /// 중분류 이름 조회
    private func fetchMidCategoryNames() -> [UUID: String] {
        let request = MidCategoryEntity.fetchRequest()

        do {
            return try coreDataManager.context.fetch(request)
                .reduce(into: [UUID: String]()) {
                    $0[$1.id] = $1.name
                }
        } catch {
            return [:]
        }
    }

    /// 소분류 이름 조회
    private func fetchSubCategoryNames() -> [UUID: String] {
        let request = SubCategoryEntity.fetchRequest()

        do {
            return try coreDataManager.context.fetch(request)
                .reduce(into: [UUID: String]()) {
                    $0[$1.id] = $1.name
                }
        } catch {
            return [:]
        }
    }
    
    /// 소분류 이미지 조회
    private func fetchSubCategoryImages() -> [UUID: UIImage] {
        let request = SubCategoryEntity.fetchRequest()

        do {
            return try coreDataManager.context.fetch(request)
                .reduce(into: [UUID: UIImage]()) {
                    guard let iconName = $1.iconName,
                          let image = UIImage(named: iconName)
                    else { return }
                    $0[$1.id] = image
                }
        } catch {
            return [:]
        }
    }
}
