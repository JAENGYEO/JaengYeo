//
//  CoreDataManager+Rx.swift
//  JaengYeo
//
//  Created by Codex on 4/23/26.
//

import CoreData
import RxSwift

//MARK: - Rx Fetched Results
extension CoreDataManager {
    /// 상품 변경 관찰
    func observeProducts(
        predicate: NSPredicate?,
        sortDescriptors: [NSSortDescriptor]
    ) -> Observable<[ProductEntity]> {
        let request = ProductEntity.fetchRequest()
        request.sortDescriptors = sortDescriptors
        request.predicate = makeActivePredicate(
            predicate,
            syncStatusKey: ProductEntity.Keys.syncStatus
        )
        return observe(request)
    }

    /// 중분류 변경 관찰
    func observeMidCategories(
        predicate: NSPredicate?,
        sortDescriptors: [NSSortDescriptor]
    ) -> Observable<[MidCategoryEntity]> {
        let request = MidCategoryEntity.fetchRequest()
        request.sortDescriptors = sortDescriptors
        request.predicate = makeActivePredicate(
            predicate,
            syncStatusKey: MidCategoryEntity.Keys.syncStatus
        )
        return observe(request)
    }

    /// 소분류 변경 관찰
    func observeSubCategories(
        predicate: NSPredicate?,
        sortDescriptors: [NSSortDescriptor]
    ) -> Observable<[SubCategoryEntity]> {
        let request = SubCategoryEntity.fetchRequest()
        request.sortDescriptors = sortDescriptors
        request.predicate = makeActivePredicate(
            predicate,
            syncStatusKey: SubCategoryEntity.Keys.syncStatus
        )
        return observe(request)
    }

    /// 장바구니 아이템 변경 관찰
    func observeCartItems(
        sortDescriptors: [NSSortDescriptor]
    ) -> Observable<[CartItemEntity]> {
        let request = CartItemEntity.fetchRequest()
        request.sortDescriptors = sortDescriptors
        return observe(request)
    }

    /// FetchRequest를 Rx 스트림으로 변환
    func observe<R: NSFetchRequestResult>(
        _ request: NSFetchRequest<R>
    ) -> Observable<[R]> {
        RxFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context
        )
        .didChangeContent
    }

    /// 삭제 대기 상태가 아닌 데이터 조건 생성
    private func makeNotPendingDeletePredicate(
        syncStatusKey: String
    ) -> NSPredicate {
        NSPredicate(
            format: "%K == nil OR %K != %@",
            syncStatusKey,
            syncStatusKey,
            SyncStatus.pendingDelete.rawValue
        )
    }

    /// 전달 조건과 삭제 대기 제외 조건 결합
    private func makeActivePredicate(
        _ predicate: NSPredicate?,
        syncStatusKey: String
    ) -> NSPredicate {
        let notDeletedPredicate = makeNotPendingDeletePredicate(
            syncStatusKey: syncStatusKey
        )

        guard let predicate else { return notDeletedPredicate }

        return NSCompoundPredicate(
            andPredicateWithSubpredicates: [
                predicate,
                notDeletedPredicate
            ]
        )
    }
}
