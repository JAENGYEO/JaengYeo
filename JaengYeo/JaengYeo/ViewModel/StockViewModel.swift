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

final class StockViewModel:  NSObject, ViewModelProtocol {
    
    private let disposeBag = DisposeBag()
    
    private let coreDataManager: CoreDataManagerProtocol
    
    private var productFetchResultController: NSFetchedResultsController<ProductEntity>?
    private var midCategoryFetchResultContoller: NSFetchedResultsController<MidCategoryEntity>?
    private var subCategoryFetchResultContoller: NSFetchedResultsController<SubCategoryEntity>?
    
    var mainCategory = BehaviorRelay<[String]>(value:
                                                [MainCategory.foodstuff.rawValue, MainCategory.household.rawValue])
    private let productsRelay = BehaviorRelay<[Product]>(value: [])

    struct Input {
        let viewDidLoad: Observable<Void>
        let mainCategorySelected: Observable<Int>
    }
    
    struct Output {
        let mainCategories: Observable<[String]>
        let products: Observable<[Product]>
        let totalCountText: Observable<Int>
    }
    
    func transform(_ input: Input) -> Output {
        input.viewDidLoad
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                self.configureProductResultController()
                self.performFetch()
            })
            .disposed(by: disposeBag)
        
        input.mainCategorySelected
            .subscribe(onNext: { [weak self] page in
                guard let self else { return }
                self.updatePredicate(for: page)
            })
            .disposed(by: disposeBag)
        
        let totalCountText = productsRelay
            .map { $0.count }
            .asObservable()
        
        return Output(
            mainCategories: mainCategory.asObservable(),
            products: productsRelay.asObservable(),
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
        request.predicate = NSPredicate(format: "mainCategory == %@", "식재료")

        let controller = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: coreDataManager.context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        controller.delegate = self
        productFetchResultController = controller
    }
    
    /// 상품 데이터 조회
    private func performFetch() {
        do {
            try productFetchResultController?.performFetch()
            updateProducts()
        } catch {
            
        }
    }
    
    /// 메인 카테고리 필터 적용
    private func updatePredicate(for selectedIndex: Int) {
        guard let request = productFetchResultController?.fetchRequest else { return }

        switch selectedIndex {
        case 0:
            request.predicate = NSPredicate(format: "mainCategory == %@", "식재료")
        case 1:
            request.predicate = NSPredicate(format: "mainCategory == %@", "생활용품")
        default:
            request.predicate = nil
        }

        performFetch()
    }
    
    /// 상품 도메인 변환 및 반영
    private func updateProducts() {
        let products = productFetchResultController?.fetchedObjects?
            .map { $0.toDomain } ?? []

        productsRelay.accept(products)
    }
}

