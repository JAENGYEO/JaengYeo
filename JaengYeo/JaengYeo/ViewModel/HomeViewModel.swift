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
    
    // 전체 현황에서 사용할 데이터 모델 구조체
    struct CategorySummary: Hashable {
        let name: String
        let totalCount: Int
        let midCategoryCount: Int
        let subCategoryCount: Int
    }
    
    enum AlertType { case expiry, lowStock}
    
    // 상태 알림에서 사용할 데이터 모델 구조체
    struct StatusSummary: Hashable {
        let type: AlertType
        let imminentCount: Int
        let totalCount: Int
        var ratio: Float { totalCount == 0 ? 0 : Float(imminentCount) / Float(totalCount) }
    }
    
    private let disposeBag = DisposeBag()
    private let coreDataManager: CoreDataManagerProtocol
    
    let navigateToUnclassified = PublishSubject<Void>()
    let navigateToCategory = PublishSubject<String>()
    
    init(coreDataManager: CoreDataManagerProtocol) {
        self.coreDataManager = coreDataManager
    }
    
    struct Input {
        let viewWillAppear: Observable<Void>
        let unclassifiedTapped: Observable<Void>
        let categoryCardTapped: Observable<String>
    }
    
    struct Output {
        let unclassifiedCount: Observable<Int>
        let categorySummaries: Observable<[CategorySummary]>
        let statusAlerts: Observable<[StatusSummary]>
    }
    
    func transform(_ input: Input) -> Output {
        // viewWillAppear 동시에 구독: share()
        let trigger = input.viewWillAppear.share()
        
        let unclassifiedCount = trigger
            .map { [weak self] _ -> Int in
                guard let self else { return 0 }
                do {
                    return try self.coreDataManager.fetchUnclassified().count
                } catch {
                    return 0
                }
            }
        
        let categorySummaries = trigger
            .map { [weak self] _ -> [CategorySummary] in
                guard let self else { return [] }
                do {
                    let food = try self.coreDataManager.fetchByMainCategory(mainCategory: "식재료")
                    let household = try self.coreDataManager.fetchByMainCategory(mainCategory: "생활용품")
                    return[
                        CategorySummary(
                            name: "식재료",
                            totalCount: food.count,
                            midCategoryCount: Set(food.compactMap { $0.midCategoryId}).count,
                            subCategoryCount: Set(food.compactMap { $0.subCategoryId}).count
                        ),
                        CategorySummary(
                            name: "생활용품",
                            totalCount: household.count,
                            midCategoryCount: Set(household.compactMap { $0.midCategoryId }).count,
                            subCategoryCount: Set(household.compactMap { $0.subCategoryId }).count
                        )
                    ].filter { $0.totalCount > 0 }
                } catch {
                    return []
                }
            }
        
        let statusAlerts = trigger
            .map { [weak self] _ -> [StatusSummary] in
                guard let self else { return [] }
                do {
                    let expiryImminent = try self.coreDataManager.fetchExpiryImminent(day: 1)
                    let expiryTotal = try self.coreDataManager.fetchWithExpiryDate()
                    let lowStockImminent = try self.coreDataManager.fetchLowStock()
                    let lowStockTotal = try self.coreDataManager.fetchLowStockEnabled()
                    return [
                        StatusSummary(type: .expiry, imminentCount: expiryImminent.count, totalCount: expiryTotal.count),
                        StatusSummary(type: .lowStock,imminentCount: lowStockImminent.count, totalCount: lowStockTotal.count)
                    ].filter { $0.totalCount > 0 }
                } catch {
                    return []
                }
            }
        
        input.unclassifiedTapped
            .bind(to: navigateToUnclassified)
            .disposed(by: disposeBag)
        
        input.categoryCardTapped
            .bind(to: navigateToCategory)
            .disposed(by: disposeBag)
        
        return Output(
            unclassifiedCount: unclassifiedCount,
            categorySummaries: categorySummaries,
            statusAlerts: statusAlerts
        )
    }
}
