//
//  UnclassifiedViewModel.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/15/26.
//

import UIKit
import RxSwift
import RxCocoa

final class UnclassifiedViewModel: ViewModelProtocol {
    
    private let disposeBag = DisposeBag()
    private let coreDateManger: CoreDataManagerProtocol
    
    let navigateToDetail = PublishSubject<UUID>()
    
    init(coreDateManger: CoreDataManagerProtocol) {
        self.coreDateManger = coreDateManger
    }
    
    struct UnclassifiedItemSummary: Hashable {
        let id: UUID
        let name: String
        let createdAt: Date
        let quantity: Int
        let image: UIImage?
        let subCategoryIconName: String?
    }
    
    struct Input {
        let viewWillAppear: Observable<Void>
    }
    
    struct Output {
        let items: Observable<[UnclassifiedItemSummary]>
    }
    
    func transform(_ input: Input) -> Output {
        let items = input.viewWillAppear
            .map { [weak self] _ -> [UnclassifiedItemSummary] in
                guard let self else { return [] }
                do {
                    let items = try self.coreDateManger.fetchUnclassified()
                        .map { payload -> UnclassifiedItemSummary in
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
                               let subCategory = payload.subCategoryId,
                               let subCategoryData = try? self.coreDateManger.fetchSubCategory(of: subCategory) {
                                iconName = subCategoryData.iconName
                            } else {
                                iconName = nil
                            }
                            return UnclassifiedItemSummary(
                                id: payload.id,
                                name: payload.name,
                                createdAt: payload.createdAt,
                                quantity: Int(payload.quantity),
                                image: image,
                                subCategoryIconName: iconName
                            )
                        }
                    return items
                } catch {
                    return []
                }
            }
        return Output(items: items)
    }
}
