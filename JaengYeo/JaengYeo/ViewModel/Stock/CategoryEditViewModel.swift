//
//  CategoryEditViewModel.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/14/26.
//


import CoreData
import Foundation
import RxRelay
import RxSwift
import UIKit

/// 분류 편집 아이템
struct CategoryEditItem: Hashable {
    /// 아이템 ID
    let id: String
    /// 아이템 타이틀
    let title: String
    /// 아이템 이미지
    let image: UIImage?
    /// 아이콘 이름
    let iconName: String
    /// 사용자 ID
    let userId: String?
}

final class CategoryEditViewModel: NSObject, ViewModelProtocol {

    //MARK: - Properties
    /// 메모리 해제 가방
    private let disposeBag = DisposeBag()
    
    /// CoreData 매니저
    private let coreDataManager: CoreDataManagerProtocol
    
    /// 선택된 메인 카테고리 인덱스
    private let selectedMainCategoryIndexRelay = BehaviorRelay<Int>(value: 0)
    /// 메인 카테고리 목록
    var mainCategory = BehaviorRelay<[String]>(value:
                                                [MainCategory.foodstuff.rawValue, MainCategory.household.rawValue])
    
    /// 중분류 조회 컨트롤러
    private var midCategoryFetchResultController: NSFetchedResultsController<MidCategoryEntity>?
    /// 소분류 조회 컨트롤러
    private var subCategoryFetchResultController: NSFetchedResultsController<SubCategoryEntity>?
    
    /// 중분류 목록
    private let midCategoriesRelay = BehaviorRelay<[CategoryEditItem]>(value: [])
    /// 소분류 목록
    private let subCategoriesRelay = BehaviorRelay<[CategoryEditItem]>(value: [])
    
    //MARK: - React Binding
    /// 입력
    struct Input {
        /// 화면 진입 이벤트
        let viewDidLoad: Observable<Void>
        /// 메인 카테고리 선택 이벤트
        let mainCategorySelected: Observable<Int>
    }
    
    /// 출력
    struct Output {
        let mainCategories: Observable<[String]>
        let presentMidCategoryItems: Observable<[CategoryEditItem]>
        let presentSubCategoryItems: Observable<[CategoryEditItem]>
    }
    
    /// 입력값 변환
    func transform(_ input: Input) -> Output {
        input.viewDidLoad
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                self.configureMidCategoryResultController()
                self.configureSubCategoryResultController()
                self.updatePredicate(for: 0)
            })
            .disposed(by: disposeBag)
        
        input.mainCategorySelected
            .subscribe(onNext: { [weak self] index in
                guard let self else { return }
                self.updatePredicate(for: index)
            })
            .disposed(by: disposeBag)

        return Output(
            mainCategories: mainCategory.asObservable(),
            presentMidCategoryItems: midCategoriesRelay.asObservable(),
            presentSubCategoryItems: subCategoriesRelay.asObservable()
        )
    }
    
    //MARK: - Init
    init(coreDataManager: CoreDataManagerProtocol) {
        self.coreDataManager = coreDataManager
        super.init()
    }
}

extension CategoryEditViewModel: NSFetchedResultsControllerDelegate {
    
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
        midCategoryFetchResultController = controller
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
        subCategoryFetchResultController = controller
    }
    
    /// 중분류 아이템 변환 및 반영
    private func updateMidCategories() {
        let categories: [CategoryEditItem] = midCategoryFetchResultController?.fetchedObjects?
            .filter { $0.syncStatus != SyncStatus.pendingDelete.rawValue }
            .map { category -> CategoryEditItem in
                let iconName = category.iconName ?? "categoryIcon"
                return CategoryEditItem(
                    id: category.id.uuidString,
                    title: category.name,
                    image: UIImage(named: iconName),
                    iconName: iconName,
                    userId: category.userId
                )
            } ?? []

        midCategoriesRelay.accept(categories)
    }
    
    /// 소분류 아이템 변환 및 반영
    private func updateSubCategories() {
        let categories: [CategoryEditItem] = subCategoryFetchResultController?.fetchedObjects?
            .filter { $0.syncStatus != SyncStatus.pendingDelete.rawValue }
            .map { category -> CategoryEditItem in
                let iconName = category.iconName ?? "categoryIcon"
                return CategoryEditItem(
                    id: category.id.uuidString,
                    title: category.name,
                    image: UIImage(named: iconName),
                    iconName: iconName,
                    userId: category.userId
                )
            } ?? []

        subCategoriesRelay.accept(categories)
    }

    /// 데이터 조회
    private func performFetch() {
        do {
            try midCategoryFetchResultController?.performFetch()
            try subCategoryFetchResultController?.performFetch()
            updateMidCategories()
            updateSubCategories()
        } catch {

        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if controller == midCategoryFetchResultController {
            updateMidCategories()
        }
        
        if controller == subCategoryFetchResultController {
            updateSubCategories()
        }
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

    private func updatePredicate(for selectedIndex: Int) {
        selectedMainCategoryIndexRelay.accept(selectedIndex)
        let mainCategoryPredicate = makeMainCategoryPredicate(for: selectedIndex)
        midCategoryFetchResultController?.fetchRequest.predicate = mainCategoryPredicate
        subCategoryFetchResultController?.fetchRequest.predicate = mainCategoryPredicate

        performFetch()
    }
}
