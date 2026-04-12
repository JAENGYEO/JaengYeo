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
    private let midCategoriesRelay = BehaviorRelay<[CategorySelectionItem]>(value: [])
    private let subCategoriesRelay = BehaviorRelay<[CategorySelectionItem]>(value: [])

    struct Input {
        let viewDidLoad: Observable<Void>
        let mainCategorySelected: Observable<Int>
    }
    
    struct Output {
        let mainCategories: Observable<[String]>
        let products: Observable<[Product]>
        let midCategories: Observable<[CategorySelectionItem]>
        let subCategories: Observable<[CategorySelectionItem]>
        let totalCountText: Observable<Int>
    }
    
    func transform(_ input: Input) -> Output {
        input.viewDidLoad
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                self.configureProductResultController()
                self.configureMidCategoryResultController()
                self.configureSubCategoryResultController()
                self.updatePredicate(for: 0)
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
            midCategories: midCategoriesRelay.asObservable(),
            subCategories: subCategoriesRelay.asObservable(),
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
        let predicate: NSPredicate?
        
        switch selectedIndex {
        case 0:
            predicate = NSPredicate(format: "mainCategory == %@", MainCategory.foodstuff.rawValue)
        case 1:
            predicate = NSPredicate(format: "mainCategory == %@", MainCategory.household.rawValue)
        default:
            predicate = nil
        }
        
        productFetchResultController?.fetchRequest.predicate = predicate
        midCategoryFetchResultContoller?.fetchRequest.predicate = predicate
        subCategoryFetchResultContoller?.fetchRequest.predicate = predicate

        performFetch()
    }
    
    /// 상품 도메인 변환 및 반영
    private func updateProducts() {
        let products = productFetchResultController?.fetchedObjects?
            .map { $0.toDomain } ?? []

        productsRelay.accept(products)
    }
    
    /// 중분류 아이템 변환 및 반영
    private func updateMidCategories() {
        let categories = midCategoryFetchResultContoller?.fetchedObjects?
            .map {
                CategorySelectionItem(
                    id: $0.id.uuidString,
                    title: $0.name,
                    image: UIImage(named: $0.iconName ?? "Category"),
                    isSelect: false
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
                    isSelect: false
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
