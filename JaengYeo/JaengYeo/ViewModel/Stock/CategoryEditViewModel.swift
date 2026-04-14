//
//  CategoryEditViewModel.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/14/26.
//


import Foundation
import CoreData
import RxSwift
import RxRelay
import UIKit

/// 분류 편집 아이템
struct CategoryEditItem: Hashable {
    /// 아이템 ID
    let id: String
    /// 아이템 타이틀
    let title: String
    /// 아이템 이미지
    let image: UIImage?
}

final class CategoryEditViewModel : NSObject, ViewModelProtocol {
    
    //MARK: - Properties
    /// 메모리 해제 가방
    private let disposeBag = DisposeBag()
    
    /// CoreData 매니저
    private let coreDataManager: CoreDataManagerProtocol
    
    /// 중분류 조회 컨트롤러
    private var midCategoryFetchResultController: NSFetchedResultsController<MidCategoryEntity>?
    /// 소분류 조회 컨트롤러
    private var subCategoryFetchResultController: NSFetchedResultsController<SubCategoryEntity>?
    
    /// 중분류 목록
    private let midCategoriesRelay = BehaviorRelay<[CategorySelectionItem]>(value: [])
    /// 소분류 목록
    private let subCategoriesRelay = BehaviorRelay<[CategorySelectionItem]>(value: [])
    
    //MARK: - React Binding
    /// 입력
    struct Input {
        
    }
    
    /// 출력
    struct Output {
        
    }
    
    /// 입력값 변환
    func transform(_ input: Input) -> Output {
        
        return Output()
    }
    
    //MARK: - Init
    init(coreDataManager: CoreDataManagerProtocol) {
        self.coreDataManager = coreDataManager
        super.init()
    }
}
