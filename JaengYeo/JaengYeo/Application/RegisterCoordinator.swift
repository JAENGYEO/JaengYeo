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
    }
}
