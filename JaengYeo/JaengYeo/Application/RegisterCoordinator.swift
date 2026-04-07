//
//  RegisterCoordinator.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/7/26.
//

import UIKit

final class RegisterCoordinator {
    let navigationController: UINavigationController
    
    private let productManager: ProductManagerProtocol
    private let categoryManager: CategoryManagerProtocol
    private let coreDataManager: CoreDataManagerProtocol
    
    init(productManager: ProductManagerProtocol, categoryManager: CategoryManagerProtocol, coreDataManager: CoreDataManagerProtocol) {
        self.productManager = productManager
        self.categoryManager = categoryManager
        self.coreDataManager = coreDataManager
        
        let viewController = RegisterViewController()
        navigationController = UINavigationController(rootViewController: viewController)
        navigationController.tabBarItem = UITabBarItem(
            title: "등록",
            image: UIImage(systemName: "camera"),
            selectedImage: UIImage(systemName: "camera.fill")
        )
    }
}
