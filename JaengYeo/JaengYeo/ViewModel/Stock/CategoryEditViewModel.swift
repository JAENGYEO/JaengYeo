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

    /// 메인 카테고리 목록
    private let mainCategoryRelay = BehaviorRelay<[String]>(
        value: [
            MainCategory.foodstuff.rawValue,
            MainCategory.household.rawValue
        ]
    )

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
        /// 삭제 버튼 선택 이벤트
        let deleteItemSelected: Observable<(CategoryEditTarget, CategoryEditItem)>
    }
    
    /// 출력
    struct Output {
        /// 메인 카테고리 목록
        let mainCategories: Observable<[String]>
        /// 중분류 목록
        let presentMidCategoryItems: Observable<[CategoryEditItem]>
        /// 소분류 목록
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
        
        input.deleteItemSelected
            .subscribe(onNext: { [weak self] target, item in
                guard let self else { return }
                do {
                    try self.deleteCategory(
                        target: target,
                        item: item
                    )
                } catch {
                }
            })
            .disposed(by: disposeBag)

        return Output(
            mainCategories: mainCategoryRelay.asObservable(),
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

//MARK: - CoreData
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
            .map {
                makeCategoryEditItem(
                    id: $0.id,
                    title: $0.name,
                    iconName: $0.iconName,
                    userId: $0.userId
                )
            } ?? []

        midCategoriesRelay.accept(categories)
    }
    
    /// 소분류 아이템 변환 및 반영
    private func updateSubCategories() {
        let categories: [CategoryEditItem] = subCategoryFetchResultController?.fetchedObjects?
            .filter { $0.syncStatus != SyncStatus.pendingDelete.rawValue }
            .map {
                makeCategoryEditItem(
                    id: $0.id,
                    title: $0.name,
                    iconName: $0.iconName,
                    userId: $0.userId
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

    /// 메인 카테고리 필터 적용
    private func updatePredicate(for selectedIndex: Int) {
        let mainCategoryPredicate = makeMainCategoryPredicate(for: selectedIndex)
        midCategoryFetchResultController?.fetchRequest.predicate = mainCategoryPredicate
        subCategoryFetchResultController?.fetchRequest.predicate = mainCategoryPredicate

        performFetch()
    }

    /// 카테고리 아이템 생성
    private func makeCategoryEditItem(
        id: UUID,
        title: String,
        iconName: String?,
        userId: String?
    ) -> CategoryEditItem {
        let iconName = iconName ?? "categoryIcon"

        return CategoryEditItem(
            id: id.uuidString,
            title: title,
            image: UIImage(named: iconName),
            iconName: iconName,
            userId: userId
        )
    }

    /// 카테고리 삭제
    private func deleteCategory(
        target: CategoryEditTarget,
        item: CategoryEditItem
    ) throws {
        guard
            item.userId != nil,
            let id = UUID(uuidString: item.id)
        else { return }
        
        switch target {
        case .midCategory:
            try coreDataManager.softDeleteMidCategory(id: id)
        case .subCategory:
            try coreDataManager.softDeleteSubCategory(id: id)
        }
    }
}
