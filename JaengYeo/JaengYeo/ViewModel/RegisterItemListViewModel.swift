//
//  RegisterItemListViewModel.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/13/26.
//

import UIKit
import RxSwift
import RxCocoa

final class RegisterItemListViewModel: ViewModelProtocol {
    
    private let itemsSubject: BehaviorSubject<[RegisterFormData]>
    private let coreDataManager: CoreDataManagerProtocol
    private let syncManager: SyncManagerProtocol
    private let authManager: AuthManagerProtocol
    private let disposeBag = DisposeBag()
    private let errorSubject = PublishSubject<String>()
    
    let navigateToDetail = PublishSubject<RegisterFormData>()
    let navigateToAdd = PublishSubject<Void>()
    let navigateToStock = PublishSubject<Void>()
    
    init(items: [RegisterFormData], coreDataManager: CoreDataManagerProtocol, syncManager: SyncManagerProtocol, authManager: AuthManagerProtocol) {
        let filledItems = items.map { item -> RegisterFormData in
            var copy = item
            if copy.purchaseDate == nil {
                copy.purchaseDate = Date()
            }
            return copy
        }
        
        self.itemsSubject = BehaviorSubject(value: filledItems)
        self.coreDataManager = coreDataManager
        self.syncManager = syncManager
        self.authManager = authManager
    }
    
    struct Input {
        let saveButtonTapped: Observable<Void>
        let addButtonTapped: Observable<Void>
        let cellTapped: Observable<RegisterFormData>
        let cellDeleted: Observable<UUID>
    }
    
    struct Output {
        let items: Observable<[RegisterFormData]>
        let error: Observable<String>
        let isSaveEnabled: Observable<Bool>
    }
    
    func transform(_ input: Input) -> Output {
        
        input.saveButtonTapped
            .withLatestFrom(itemsSubject)
            .bind(onNext: { [weak self] items in
                self?.saveAllItems(items: items)
            })
            .disposed(by: disposeBag)
        
        input.cellTapped
            .bind(to: navigateToDetail)
            .disposed(by: disposeBag)
        
        input.addButtonTapped
            .bind(to: navigateToAdd)
            .disposed(by: disposeBag)
        
        input.cellDeleted
            .bind(onNext: { [weak self] id in
                self?.deleteItem(id: id)
            })
            .disposed(by: disposeBag)
        
        return Output(
            items: itemsSubject.asObservable(),
            error: errorSubject.asObservable(),
            isSaveEnabled: itemsSubject.map { items in
                !items.isEmpty && items.allSatisfy { item in
                    item.name != nil &&
                    item.mainCategory != nil &&
                    item.quantity != nil &&
                    item.purchaseDate != nil
                }
            }.distinctUntilChanged()
        )
    }
}

extension RegisterItemListViewModel {
    func updateItem(item: RegisterFormData) {
        guard var current = try? itemsSubject.value(),
              let index = current.firstIndex(where: { $0.id == item.id }) else { return }
        current[index] = item
        itemsSubject.onNext(current)
    }
    
    func appendItem(item: RegisterFormData) {
        guard var current = try? itemsSubject.value() else { return }
        current.append(item)
        itemsSubject.onNext(current)
    }
    
    func hasItem(id: UUID) -> Bool {
        (try? itemsSubject.value())?.contains(where: { $0.id == id }) ?? false
    }
}

extension RegisterItemListViewModel {
    private func saveAllItems(items: [RegisterFormData]) {
        guard let userId = authManager.currentUserId else {
            errorSubject.onNext("로그인이 필요합니다.")
            return
        }
        let now = Date()
        let payloads: [ProductPayload] = items.compactMap { item in
            guard let name = item.name, let mainCategory = item.mainCategory else { return nil }
            let imageUrl: String? = {
                guard let image = item.image else { return nil }
                return saveImage(image: image)
            }()
            
            return ProductPayload(
                id: item.id,
                userId: userId,
                name: name,
                quantity: Int32(item.quantity ?? 0),
                quantityUnit: item.quantityUnit,
                mainCategory: mainCategory,
                midCategoryId: item.midCategory,
                subCategoryId: item.subCategory,
                purchaseDate: item.purchaseDate,
                expiryDate: item.expiryDate,
                price: Int32(item.price ?? 0),
                locationMemo: nil,
                memo: item.memo,
                imageUrl: imageUrl, //TODO: 수정 필요
                isClassified: item.midCategory != nil,
                lowStockThreshold: item.lowStockThreshold.map { Int32($0) },
                isFavorite: false, //TODO: 수정 필요
                createdAt: now,
                updatedAt: now,
                syncStatus: SyncStatus.pendingUpload.rawValue,
                isLowStockNotificationEnabled: item.isLowStockNotificationEnabled ?? false,
                caution: item.caution,
                brand: item.brand
            )
        }
        do {
            try coreDataManager.createProducts(payloads: payloads)
            syncManager.syncIfConnected()
            navigateToStock.onNext(())
        } catch {
            errorSubject.onNext("저장 실패")
        }
    }
}

extension RegisterItemListViewModel {
    private func saveImage(image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let fileName = UUID().uuidString + ".jpg"
        let url = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
        do {
            try data.write(to: url)
            return fileName
        } catch {
            return nil
        }
    }
}

extension RegisterItemListViewModel {
    private func deleteItem(id: UUID) {
        guard var current = try? itemsSubject.value() else { return }
        current.removeAll() { $0.id == id }
        itemsSubject.onNext(current)
    }
}
