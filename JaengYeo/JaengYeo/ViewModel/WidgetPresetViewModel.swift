//
//  WidgetPresetViewModel.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/30/26.
//

import Foundation
import RxSwift
import RxCocoa

final class WidgetPresetViewModel: ViewModelProtocol {
    struct PresetSummary: Hashable {
        let id: UUID
        let name: String
        let productCount: Int
    }
    
    private let disposeBag = DisposeBag()
    private let coreDataManager: CoreDataManagerProtocol
    
    let navigateToCreate = PublishSubject<Void>()
    let navigateToEdit = PublishSubject<UUID>()
    
    init(coreDataManager: CoreDataManagerProtocol) {
        self.coreDataManager = coreDataManager
    }
    
    struct Input {
        let viewWillAppear: Observable<Void>
        let itemSelected: Observable<UUID>
        let addButtonTapped: Observable<Void>
        let deletePreset: Observable<UUID>
    }
    
    struct Output {
        let presets: Observable<[PresetSummary]>
        let canAddMore: Observable<Bool>
    }
    
    func transform(_ input: Input) -> Output {
        let deletePreset = input.deletePreset
            .do(onNext: { [weak self] id in
                try? self?.coreDataManager.deleteWidgetPreset(id: id)
            })
            .map { _ in () }
        
        let presets = Observable.merge(input.viewWillAppear, deletePreset)
            .map { [weak self] _ -> [PresetSummary] in
                guard let self else { return [] }
                do {
                    return try self.coreDataManager.fetchAllWidgetPresets()
                        .map { payload in
                            PresetSummary(
                                id: payload.id,
                                name: payload.name,
                                productCount: payload.productIDs.count
                            )
                        }
                } catch {
                    return []
                }
            }
            .share(replay: 1)
        
        let canAddMore = presets.map { $0.count < 5 }
        
        input.itemSelected
            .bind(to: navigateToEdit)
            .disposed(by: disposeBag)
        
        input.addButtonTapped
            .bind(to: navigateToCreate)
            .disposed(by: disposeBag)
        
        return Output(presets: presets, canAddMore: canAddMore)
    }
}
