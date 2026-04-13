//
//  RegisterCoordinator.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/7/26.
//

import UIKit
import Supabase

final class RegisterCoordinator {
    let navigationController: UINavigationController
    
    private let productManager: ProductManagerProtocol
    private let categoryManager: CategoryManagerProtocol
    private let coreDataManager: CoreDataManagerProtocol
    private let client: SupabaseClient
    
    private weak var listViewController: RegisterItemListViewController?
    
    init(productManager: ProductManagerProtocol, categoryManager: CategoryManagerProtocol, coreDataManager: CoreDataManagerProtocol, client: SupabaseClient) {
        self.productManager = productManager
        self.categoryManager = categoryManager
        self.coreDataManager = coreDataManager
        self.client = client
        
        let viewModel = RegisterViewModel(client: client)
        let viewController = RegisterViewController(viewModel: viewModel)
        navigationController = UINavigationController(rootViewController: viewController)
        navigationController.tabBarItem = UITabBarItem(
            title: "등록",
            image: UIImage(systemName: "camera"),
            selectedImage: UIImage(systemName: "camera.fill")
        )
        viewController.delegate = self
    }
}

extension RegisterCoordinator: RegisterViewControllerDelegate {
    func pushItemListView(items: [RegisterFormData]) {
        let viewController = RegisterItemListViewController(items: items, pageTitle: "AI 인식 결과")
        viewController.delegate = self
        listViewController = viewController
        navigationController.pushViewController(viewController, animated: true)
    }
}

extension RegisterCoordinator: RegisterItemListViewControllerDelegate {
    func pushRegisterDetailView(item: RegisterFormData) {
        let viewController = RegisterDetailViewController(item: item)
        viewController.delegate = self
        navigationController.pushViewController(viewController, animated: true)
    }
    
    func saveItems(items: [RegisterFormData]) {
        let now = Date()
        items.forEach { item in
            guard let name = item.name, let mainCategory = item.mainCategory else { return }
            let payload = ProductPayload(
                id: item.id,
                userId: Constants.Dev.userId,
                name: name,
                quantity: Int32(item.quantity ?? 0),
                quantityUnit: item.quantityUnit,
                mainCategory: mainCategory,
                midCategoryId: item.midCategory,
                subCategoryId: item.subCategory,
                purchaseDate: item.purchaseDate,
                expiryDate: item.expiryDate,
                price: Int32(item.price ?? 0),
                locationMemo: item.locationMemo,
                memo: item.memo,
                imageUrl: nil, //TODO: 수정 필요
                isClassified: false,
                lowStockThreshold: Int32(item.lowStockThreshold ?? 1),
                isFavorite: false, //TODO: 수정 필요
                createdAt: now,
                updatedAt: now,
                syncStatus: SyncStatus.pendingUpload.rawValue,
                isLowStockNotificationEnabled: item.isLowStockNotificationEnabled ?? false,
                caution: item.caution,
                brand: item.brand
            )
            try? coreDataManager.createProduct(payload)
        }
    }
}

extension RegisterCoordinator: RegisterDetailViewControllerDelegate {
    func didTapConfirmButton(item: RegisterFormData) {
        listViewController?.updateItem(item: item)
    }
}
