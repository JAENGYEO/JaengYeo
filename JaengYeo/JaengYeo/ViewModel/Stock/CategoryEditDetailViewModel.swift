//
//  CategoryEditDetailViewModel.swift
//  JaengYeo
//
//  Created by Codex on 4/15/26.
//

import Foundation
import RxRelay
import RxSwift

/// 편집 대상 분류
enum CategoryEditTarget {
    case midCategory
    case subCategory

    var title: String {
        switch self {
        case .midCategory:
            return "중분류"
        case .subCategory:
            return "소분류"
        }
    }
}

/// 분류 편집 화면 모드
enum CategoryEditMode {
    case add(CategoryEditTarget, String)
    case edit(CategoryEditTarget, CategoryEditItem, String)

    /// 네비게이션 타이틀
    var navigationTitle: String {
        switch self {
        case .add(let target, _):
            return "\(target.title) 카테고리 추가"
        case .edit(let target, _, _):
            return "\(target.title) 카테고리 편집"
        }
    }

    /// 완료 버튼 타이틀
    var buttonTitle: String {
        switch self {
        case .add:
            return "카테고리 생성"
        case .edit:
            return "카테고리 수정"
        }
    }

    /// 편집 아이템
    var item: CategoryEditItem? {
        switch self {
        case .add:
            return nil
        case .edit(_, let item, _):
            return item
        }
    }

    /// 선택 가능 아이콘 목록
    var iconNames: [String] {
        switch (target, mainCategory) {
        case (.midCategory, MainCategory.foodstuff.rawValue):
            return FoodMidCategoryIcon.iconNames
        case (.subCategory, MainCategory.foodstuff.rawValue):
            return FoodSubCategoryIcon.iconNames
        case (.midCategory, MainCategory.household.rawValue):
            return HouseholdMidCategoryIcon.iconNames
        case (.subCategory, MainCategory.household.rawValue):
            return HouseholdSubCategoryIcon.iconNames
        default:
            return ["categoryIcon"]
        }
    }

    /// 현재 선택된 아이콘 이름
    var selectedIconName: String? {
        item?.iconName
    }

    private var target: CategoryEditTarget {
        switch self {
        case .add(let target, _):
            return target
        case .edit(let target, _, _):
            return target
        }
    }
    
    private var mainCategory: String {
        switch self {
        case .add(_, let mainCategory):
            return mainCategory
        case .edit(_, _, let mainCategory):
            return mainCategory
        }
    }
}

final class CategoryEditDetailViewModel: ViewModelProtocol {

    //MARK: - Properties
    /// 메모리 해제 가방
    private let disposeBag = DisposeBag()
    /// 편집 모드
    private let mode: CategoryEditMode
    /// CoreData 매니저
    private let coreDataManager: CoreDataManagerProtocol

    //MARK: - React Binding
    /// 입력
    struct Input {
        /// 이름 입력값
        let nameText: Observable<String?>
        /// 아이콘 선택값
        let iconNameSelected: Observable<String>
        /// 생성/수정 버튼 선택
        let confirmTapped: Observable<Void>
        /// 삭제 버튼 선택
        let deleteTapped: Observable<Void>
    }

    /// 출력
    struct Output {
        /// 작업 완료 이벤트
        let completed: Observable<Void>
    }

    /// 입력값 변환
    func transform(_ input: Input) -> Output {
        let completedRelay = PublishRelay<Void>()
        let nameTextRelay = BehaviorRelay<String>(value: "")
        let iconNameRelay = BehaviorRelay<String>(
            value: mode.selectedIconName ?? "categoryIcon"
        )

        input.nameText
            .map { $0 ?? "" }
            .bind(to: nameTextRelay)
            .disposed(by: disposeBag)
        
        input.iconNameSelected
            .bind(to: iconNameRelay)
            .disposed(by: disposeBag)

        input.confirmTapped
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                let name = nameTextRelay.value
                let iconName = iconNameRelay.value
                guard !name.isEmpty else { return }

                do {
                    try self.saveCategory(
                        name: name,
                        iconName: iconName
                    )
                    completedRelay.accept(())
                } catch {
                }
            })
            .disposed(by: disposeBag)

        input.deleteTapped
            .subscribe(onNext: { [weak self] in
                guard let self else { return }

                do {
                    try self.deleteCategory()
                    completedRelay.accept(())
                } catch {
                }
            })
            .disposed(by: disposeBag)

        return Output(
            completed: completedRelay.asObservable()
        )
    }

    //MARK: - Init
    init(
        mode: CategoryEditMode,
        coreDataManager: CoreDataManagerProtocol
    ) {
        self.mode = mode
        self.coreDataManager = coreDataManager
    }
}

//MARK: - CoreData
private extension CategoryEditDetailViewModel {
    /// 카테고리 저장
    func saveCategory(
        name: String,
        iconName: String
    ) throws {
        switch mode {
        case .add(let target, let mainCategory):
            try createCategory(
                target: target,
                mainCategory: mainCategory,
                name: name,
                iconName: iconName
            )

        case .edit(let target, let item, _):
            try updateCategory(
                target: target,
                item: item,
                name: name,
                iconName: iconName
            )
        }
    }

    /// 카테고리 생성
    func createCategory(
        target: CategoryEditTarget,
        mainCategory: String,
        name: String,
        iconName: String
    ) throws {
        switch target {
        case .midCategory:
            try coreDataManager.createMidCategory(
                makeMidCategoryPayload(
                    mainCategory: mainCategory,
                    name: name,
                    iconName: iconName
                )
            )

        case .subCategory:
            try coreDataManager.createSubCategory(
                makeSubCategoryPayload(
                    mainCategory: mainCategory,
                    name: name,
                    iconName: iconName
                )
            )
        }
    }

    /// 카테고리 수정
    func updateCategory(
        target: CategoryEditTarget,
        item: CategoryEditItem,
        name: String,
        iconName: String
    ) throws {
        guard let id = UUID(uuidString: item.id) else { return }

        switch target {
        case .midCategory:
            let payload = try coreDataManager.fetchMidCategory(of: id)
            try coreDataManager.updateMidCategory(
                MidCategoryPayload(
                    id: payload.id,
                    userId: payload.userId,
                    mainCategory: payload.mainCategory,
                    name: name,
                    iconName: iconName,
                    sortOrder: payload.sortOrder,
                    createdAt: payload.createdAt,
                    updatedAt: Date(),
                    syncStatus: SyncStatus.pendingUpload.rawValue
                )
            )

        case .subCategory:
            let payload = try coreDataManager.fetchSubCategory(of: id)
            try coreDataManager.updateSubCategory(
                SubCategoryPayload(
                    id: payload.id,
                    userId: payload.userId,
                    mainCategory: payload.mainCategory,
                    name: name,
                    iconName: iconName,
                    thumbnailKey: payload.thumbnailKey,
                    sortOrder: payload.sortOrder,
                    createdAt: payload.createdAt,
                    updatedAt: Date(),
                    syncStatus: SyncStatus.pendingUpload.rawValue
                )
            )
        }
    }

    /// 카테고리 삭제
    func deleteCategory() throws {
        guard
            let item = mode.item,
            item.userId != nil,
            let id = UUID(uuidString: item.id)
        else { return }

        switch mode {
        case .add:
            return
        case .edit(let target, _, _):
            switch target {
            case .midCategory:
                try coreDataManager.softDeleteMidCategory(id: id)
            case .subCategory:
                try coreDataManager.softDeleteSubCategory(id: id)
            }
        }
    }
}

//MARK: - Payload
private extension CategoryEditDetailViewModel {
    /// 중분류 Payload 생성
    func makeMidCategoryPayload(
        mainCategory: String,
        name: String,
        iconName: String
    ) throws -> MidCategoryPayload {
        let now = Date()

        return MidCategoryPayload(
            id: UUID(),
            userId: Constants.Dev.userId,
            mainCategory: mainCategory,
            name: name,
            iconName: iconName,
            sortOrder: try nextMidCategorySortOrder(mainCategory: mainCategory),
            createdAt: now,
            updatedAt: now,
            syncStatus: SyncStatus.pendingUpload.rawValue
        )
    }

    /// 소분류 Payload 생성
    func makeSubCategoryPayload(
        mainCategory: String,
        name: String,
        iconName: String
    ) throws -> SubCategoryPayload {
        let now = Date()

        return SubCategoryPayload(
            id: UUID(),
            userId: Constants.Dev.userId,
            mainCategory: mainCategory,
            name: name,
            iconName: iconName,
            thumbnailKey: nil,
            sortOrder: try nextSubCategorySortOrder(mainCategory: mainCategory),
            createdAt: now,
            updatedAt: now,
            syncStatus: SyncStatus.pendingUpload.rawValue
        )
    }

    /// 중분류 정렬 순서 생성
    func nextMidCategorySortOrder(mainCategory: String) throws -> Int32 {
        let sortOrders = try coreDataManager
            .fetchAllMidCategories(mainCategory: mainCategory)
            .map { $0.sortOrder }

        return (sortOrders.max() ?? -1) + 1
    }

    /// 소분류 정렬 순서 생성
    func nextSubCategorySortOrder(mainCategory: String) throws -> Int32 {
        let sortOrders = try coreDataManager
            .fetchAllSubCategories(mainCategory: mainCategory)
            .map { $0.sortOrder }

        return (sortOrders.max() ?? -1) + 1
    }
}
