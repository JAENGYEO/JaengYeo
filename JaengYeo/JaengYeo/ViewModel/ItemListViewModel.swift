//
//  ItemListViewModel.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/17/26.
//

import UIKit
import RxSwift
import RxCocoa

enum ItemListType {
    case unclassified
    case expiryImminent(day: Int)
    case lowStock
    
    var title: String {
        switch self {
        case .unclassified:
            return "미분류 상품"
        case .expiryImminent:
            return "유통기한 임박 상품"
        case .lowStock:
            return "재고 부족 상품"
        }
    }
    
    var info: String {
        switch self {
        case .unclassified:
            return "분류가 덜 된 상품들의 세부정보를 입력해주세요"
        case .expiryImminent:
            return "유통기한 임박! 잊지 말고 오늘 사용하세요"
        case .lowStock:
            return "재고 부족! 빨리 구매하세요"
        }
    }
}

final class ItemListViewModel: ViewModelProtocol {
    
    private let disposeBag = DisposeBag()
    private let coreDataManager: CoreDataManagerProtocol
    
    let listType: ItemListType
    let navigateToDetail = PublishSubject<UUID>()
    
    
    init(coreDataManager: CoreDataManagerProtocol, listType: ItemListType) {
        self.coreDataManager = coreDataManager
        self.listType = listType
    }
    struct ItemSummary: Hashable {
        let id: UUID
        let name: String
        let createdAt: Date
        let quantity: Int
        let image: UIImage?
        let subCategoryIconName: String?
        let expiryDaysLeft: Int?
    }
    
    struct Input {
        let viewWillAppear: Observable<Void>
    }
    
    struct Output {
        let items: Observable<[ItemSummary]>
    }
    
    func transform(_ input: Input) -> Output {
        let items = input.viewWillAppear
            .map { [weak self] _ -> [ItemSummary] in
                guard let self else { return [] }
                do {
                    let payloads: [ProductPayload]
                    switch self.listType {
                    case .unclassified:
                        payloads = try self.coreDataManager.fetchUnclassified()
                    case .expiryImminent(let day):
                        payloads = try self.coreDataManager.fetchExpiryImminent(day: day)
                    case .lowStock:
                        payloads = try self.coreDataManager.fetchLowStock()
                    }
                    return payloads.map { payload -> ItemSummary in
                        let image: UIImage?
                        if let fileName = payload.imageUrl {
                            let url = FileManager.default
                                .urls(for: .documentDirectory, in: .userDomainMask)[0]
                                .appendingPathComponent(fileName)
                            image = UIImage(contentsOfFile: url.path)
                        } else {
                            image = nil
                        }
                        let iconName: String?
                        if image == nil,
                           let subCategoryId = payload.subCategoryId,
                           let subCategory = try? self.coreDataManager.fetchSubCategory(of: subCategoryId) {
                            iconName = subCategory.iconName
                        } else {
                            iconName = nil
                        }
                        let expiryDaysLeft: Int?
                        if case .expiryImminent = self.listType, let expiryDate = payload.expiryDate {
                            let today = Calendar.current.startOfDay(for: Date())
                            let expiryDay = Calendar.current.startOfDay(for: expiryDate)
                            expiryDaysLeft = Calendar.current.dateComponents([.day], from: today, to: expiryDay).day
                        } else {
                            expiryDaysLeft = nil
                        }
                        return ItemSummary(
                            id: payload.id,
                            name: payload.name,
                            createdAt: payload.createdAt,
                            quantity: Int(payload.quantity),
                            image: image,
                            subCategoryIconName: iconName,
                            expiryDaysLeft: expiryDaysLeft
                        )
                    }
                } catch {
                    return []
                }
            }
        return Output(items: items)
    }
}
