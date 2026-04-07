//
//  SyncManager.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/7/26.
//

import Foundation
import Network

final class SyncManager: SyncManagerProtocol {

    private let productManager: ProductManagerProtocol
    private let categoryManager: CategoryManagerProtocol
    private let coreDataManager: CoreDataManagerProtocol
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.jaengyeo.networkMonitor")
    
    private var isMonitoring = false // 네트워크 중복 호출 방지용
    private var isSyncing = false // 동기화 중복 실행 방지용
    
    init(productManager: ProductManagerProtocol, categoryManager: CategoryManagerProtocol, coreDataManager: CoreDataManagerProtocol) {
        self.productManager = productManager
        self.categoryManager = categoryManager
        self.coreDataManager = coreDataManager
    }
    
    deinit {
        monitor.cancel()
    }
    
    // MARK: - 네트워크 상태 감지 및 온라인 복귀 시 동기화
    func networkCheck() {
        guard !isMonitoring else { return }
        isMonitoring = true
        monitor.pathUpdateHandler = { [weak self] path in // 네트워크 상태 변경 시 호출
            if path.status == .satisfied { // 인터넷 연결됨 -> 동기화 진행
                Task {
                    await self?.synchronize()
                }
            }
        }
        monitor.start(queue: monitorQueue) // 백그라운드에서 네트워크 상태 감지 시작
    }
    
    // MARK: - pending 항목 전체 동기화
    func synchronize() async {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false } // 동기화 완료 시 false 복원
        await syncPendingUploadProducts()
        await syncPendingDeleteProducts()
        await syncPendingUploadSubCategories()
        await syncPendingDeleteSubCategories()
        await syncPendingUploadMidCategories()
        await syncPendingDeleteMidCategories()
    }
}

//MARK: - Products (upload, delete 상태 동기화)
extension SyncManager {
    private func syncPendingUploadProducts() async {
        guard let payloads = try? coreDataManager.fetchPendingUploadProducts() else { return }
        for payload in payloads {
            let product = payload.toDomain()
            let dto = ProductDTO(from: product)
            do {
                try await productManager.upsert(dto: dto)
                try coreDataManager.updateProductSyncStatus(id: payload.id)
            } catch { //TODO: 에러 처리 필요
            }
        }
    }
    
    private func syncPendingDeleteProducts() async {
        guard let payloads = try? coreDataManager.fetchPendingDeleteProducts() else { return }
        for payload in payloads {
            do {
                try await productManager.softDeleteProduct(id: payload.id)
                try coreDataManager.updateProductSyncStatus(id: payload.id)
            } catch {  //TODO: 에러 처리 필요
            }
        }
    }
}

//MARK: - SubCategory (upload, delete 상태 동기화)
extension SyncManager {
    private func syncPendingUploadSubCategories() async {
        guard let payloads = try? coreDataManager.fetchPendingUploadSubCategories() else { return }
        for payload in payloads {
            let subCategory = payload.toDomain()
            let dto = SubCategoryDTO(from: subCategory)
            do {
                try await categoryManager.upsertSubCategory(dto: dto)
                try coreDataManager.updateSubCategorySyncStatus(id: payload.id)
            } catch { //TODO: 에러 처리 필요
            }
        }
    }
    
    private func syncPendingDeleteSubCategories() async {
        guard let payloads = try? coreDataManager.fetchPendingDeleteSubCategories() else { return }
        for payload in payloads {
            do {
                try await categoryManager.softDeleteSubCategory(id: payload.id)
                try coreDataManager.updateSubCategorySyncStatus(id: payload.id)
            } catch { //TODO: 에러 처리 필요
            }
        }
    }
}

//MARK: - MidCategory (upload, delete 상태 동기화)
extension SyncManager {
    private func syncPendingUploadMidCategories() async {
        guard let payloads = try? coreDataManager.fetchPendingUploadMidCategories() else { return }
        for payload in payloads {
            let midCategory = payload.toDomain()
            let dto = MidCategoryDTO(from: midCategory)
            do {
                try await categoryManager.upsertMidCategory(dto: dto)
                try coreDataManager.updateMidCategorySyncStatus(id: payload.id)
            } catch {//TODO: 에러 처리 필요
            }
        }
    }
    
    private func syncPendingDeleteMidCategories() async {
        guard let payloads = try? coreDataManager.fetchPendingDeleteMidCategories() else { return }
        for payload in payloads {
            do {
                try await categoryManager.softDeleteMidCategory(id: payload.id)
                try coreDataManager.updateMidCategorySyncStatus(id: payload.id)
            } catch { //TODO: 에러 처리 필요
            }
        }
    }
}
