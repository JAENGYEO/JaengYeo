//
//  HomeViewModel.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/15/26.
//

import Foundation
import RxSwift
import RxCocoa

final class HomeViewModel: ViewModelProtocol {
    
    private let disposeBag = DisposeBag()
    private let coreDataManager: CoreDataManagerProtocol
    
    let navigateToUnclassified = PublishSubject<Void>()
    
    init(coreDataManager: CoreDataManagerProtocol) {
        self.coreDataManager = coreDataManager
    }
    
    struct Input {
        let viewWillAppear: Observable<Void>
        let unclassifiedTapped: Observable<Void>
    }
    
    struct Output {
        let unclassifiedCount: Observable<Int>
    }
    
    func transform(_ input: Input) -> Output {
        let unclassifiedCount = input.viewWillAppear
            .map { [weak self] _ -> Int in
                guard let self else { return 0 }
                do {
                    return try self.coreDataManager.fetchUnclassified().count
                } catch {
                    return 0
                }
            }
        
        input.unclassifiedTapped
            .bind(to: navigateToUnclassified)
            .disposed(by: disposeBag)
        
        return Output(unclassifiedCount: unclassifiedCount)
    }
}
