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
    /// 선택된 메인 카테고리 인덱스
    private let selectedMainCategoryIndexRelay = BehaviorRelay<Int>(value: 0)

    /// 중분류 조회 스트림 해제 가방
    private var midCategoryObservationDisposeBag = DisposeBag()
    /// 소분류 조회 스트림 해제 가방
    private var subCategoryObservationDisposeBag = DisposeBag()
    
    /// 중분류 목록
    private let midCategoriesRelay = BehaviorRelay<[CategoryEditItem]>(value: [])
    /// 소분류 목록
    private let subCategoriesRelay = BehaviorRelay<[CategoryEditItem]>(value: [])
    
    //MARK: - React Binding
    /// 입력
    struct Input {
        /// 화면 진입 이벤트
        let viewDidLoad: Observable<Void>
        /// 화면 재진입 이벤트
        let viewWillAppear: Observable<Int>
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
                self.updatePredicate(for: 0)
            })
            .disposed(by: disposeBag)

        input.viewWillAppear
            .subscribe(onNext: { [weak self] index in
                guard let self else { return }
                self.updatePredicate(for: index)
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
                    self.updatePredicate(
                        for: self.selectedMainCategoryIndexRelay.value
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
private extension CategoryEditViewModel {
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
        .map { [weak self] entities -> [CategoryEditItem] in
            guard let self else { return [] }
            return entities
                .map {
                    self.makeCategoryEditItem(
                        id: $0.id,
                        title: $0.name,
                        iconName: $0.iconName,
                        userId: $0.userId
                    )
                }
        }
        .bind(to: midCategoriesRelay)
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
        .map { [weak self] entities -> [CategoryEditItem] in
            guard let self else { return [] }
            return entities
                .map {
                    self.makeCategoryEditItem(
                        id: $0.id,
                        title: $0.name,
                        iconName: $0.iconName,
                        userId: $0.userId
                    )
                }
        }
        .bind(to: subCategoriesRelay)
        .disposed(by: subCategoryObservationDisposeBag)
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
        selectedMainCategoryIndexRelay.accept(selectedIndex)
        let mainCategoryPredicate = makeMainCategoryPredicate(for: selectedIndex)
        bindMidCategories(predicate: mainCategoryPredicate)
        bindSubCategories(predicate: mainCategoryPredicate)
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
