//
//  WidgetPresetEditViewModel.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/30/26.
//

import Foundation
import RxSwift
import RxCocoa

final class WidgetPresetEditViewModel: ViewModelProtocol {
    enum Mode {
        case create
        case edit(WidgetPresetPayload)
        
        var isEdit: Bool {
            if case .edit = self { return true}
            return false
        }
    }
    
    struct SelectedProduct: Hashable {
        let id: UUID
        let name: String
        let mainCategory: String
    }
    
    private let disposeBag = DisposeBag()
    private let coreDataManager: CoreDataManagerProtocol
    private let mode: Mode
    
    private let nameSubject: BehaviorSubject<String>
    private let selectedIDsSubject: BehaviorSubject<[UUID]>
    
    let navigateToProductSelection = PublishSubject<[UUID]>()
    let saveCompleted = PublishSubject<Void>()
    let deleteCompleted = PublishSubject<Void>()
    
    init(coreDataManager: CoreDataManagerProtocol, mode: Mode) {
        self.coreDataManager = coreDataManager
        self.mode = mode
        switch mode {
        case .create:
            self.nameSubject = BehaviorSubject(value: "")
            self.selectedIDsSubject = BehaviorSubject(value: [])
        case .edit(let widgetPresetPayload):
            self.nameSubject = BehaviorSubject(value: widgetPresetPayload.name)
            self.selectedIDsSubject = BehaviorSubject(value: widgetPresetPayload.productIDs)
        }
    }
    
    struct Input {
        let nameChanged: Observable<String>
        let addButtonTapped: Observable<Void>
        let removeProduct: Observable<UUID>
        let saveButtonTapped: Observable<Void>
        let deleteButtonTapped: Observable<Void>
        let productSelectionResult: Observable<[UUID]>
    }
    
    struct Output {
        let initialName: Observable<String>
        let selectedProducts: Observable<[SelectedProduct]>
        let canSave: Observable<Bool>
        let isEditMode: Observable<Bool>
        let title: Observable<String>
    }
    
    func transform(_ input: Input) -> Output {
        input.nameChanged
            .skip(1)
            .bind(to: nameSubject)
            .disposed(by: disposeBag)
        
        input.productSelectionResult
            .bind(to: selectedIDsSubject)
            .disposed(by: disposeBag)
        
        input.removeProduct
            .withLatestFrom(selectedIDsSubject) { id, ids in
                ids.filter { $0 != id }
            }
            .bind(to: selectedIDsSubject)
            .disposed(by: disposeBag)
        
        input.addButtonTapped
            .withLatestFrom(selectedIDsSubject)
            .bind(to: navigateToProductSelection)
            .disposed(by: disposeBag)
        
        input.saveButtonTapped
            .withLatestFrom(Observable.combineLatest(nameSubject, selectedIDsSubject))
            .bind(onNext: { [weak self] name, ids in
                guard let self else { return }
                let trimmed = name.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty, !ids.isEmpty else { return }
                let now = Date()
                do {
                    switch self.mode {
                    case .create:
                        let payload = WidgetPresetPayload(
                            id: UUID(),
                            name: trimmed,
                            productIDs: ids,
                            createdAt: now,
                            updatedAt: now
                        )
                        try self.coreDataManager.createWidgetPreset(payload: payload)
                    case .edit(let widgetPresetPayload):
                        let payload = WidgetPresetPayload(
                            id: widgetPresetPayload.id,
                            name: trimmed,
                            productIDs: ids,
                            createdAt: widgetPresetPayload.createdAt,
                            updatedAt: now
                        )
                        try self.coreDataManager.updateWidgetPreset(payload: payload)
                    }
                    self.saveCompleted.onNext(())
                } catch {
                }
            })
            .disposed(by: disposeBag)
        
        input.deleteButtonTapped
            .bind(onNext: { [weak self] in
                guard let self, case .edit(let widgetPresetPayload) = self.mode else { return }
                do {
                    try self.coreDataManager.deleteWidgetPreset(id: widgetPresetPayload.id)
                    self.deleteCompleted.onNext(())
                } catch {
                }
            })
            .disposed(by: disposeBag)
        
        let selectedProducts = selectedIDsSubject
            .map { [weak self] ids -> [SelectedProduct] in
                guard let self else { return [] }
                return ids.compactMap { id in
                    guard let payload = try? self.coreDataManager.fetchProduct(of: id) else { return nil }
                    return SelectedProduct(id: payload.id, name: payload.name, mainCategory: payload.mainCategory)
                }
            }
        let canSave = Observable.combineLatest(nameSubject, selectedIDsSubject) { name, ids in
            !name.trimmingCharacters(in: .whitespaces).isEmpty && !ids.isEmpty
        }
        
        let initialNameText = (try? nameSubject.value()) ?? ""
        let titleText = mode.isEdit ? "프리셋 편집" : "프리셋 추가"
        
        return Output(
            initialName: Observable.just(initialNameText),
            selectedProducts: selectedProducts,
            canSave: canSave,
            isEditMode: Observable.just(mode.isEdit),
            title: Observable.just(titleText)
        )
    }
}
