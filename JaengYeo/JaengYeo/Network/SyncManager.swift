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
    
    init(productManager: ProductManagerProtocol, categoryManager: CategoryManagerProtocol, coreDataManager: CoreDataManagerProtocol) {
        self.productManager = productManager
        self.categoryManager = categoryManager
        self.coreDataManager = coreDataManager
    }
    
    // MARK: - 네트워크 상태 감지 및 온라인 복귀 시 동기화
    func networkCheck() {
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
            try? await productManager.update(dto: dto)
        }
    }
    
    private func syncPendingDeleteProducts() async {
        guard let payloads = try? coreDataManager.fetchPendingDeleteProducts() else { return }
        for payload in payloads {
            try? await productManager.softDeleteProduct(id: payload.id)
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
            try? await categoryManager.createSubCategory(dto: dto)
        }
    }
    
    private func syncPendingDeleteSubCategories() async {
        guard let payloads = try? coreDataManager.fetchPendingDeleteSubCategories() else { return }
        for payload in payloads {
            try? await categoryManager.softDeleteSubCategory(id: payload.id)
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
            try? await categoryManager.createMidCategory(dto: dto)
        }
    }
    
    private func syncPendingDeleteMidCategories() async {
        guard let payloads = try? coreDataManager.fetchPendingDeleteMidCategories() else { return }
        for payload in payloads {
            try? await categoryManager.softDeleteMidCategory(id: payload.id)
        }
    }
}
