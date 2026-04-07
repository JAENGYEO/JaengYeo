//
//  AppCoordinator.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/7/26.
//

import UIKit

final class AppCoordinator {
    private let window: UIWindow
    
    init(window: UIWindow) {
        self.window = window
    }
    
    func start() {
        let client = makeSupabaseClient()
        let productManager = ProductManager(client: client)
        let categoryManager = CategoryManager(client: client)
        let coreDataManager = CoreDataManager()
        let syncManager = SyncManager(
            productManager: productManager,
            categoryManager: categoryManager,
            coreDataManager: coreDataManager
        )
        syncManager.networkCheck()
        
        let homeCoordinator = HomeCoordinator(
            productManager: productManager,
            categoryManager: categoryManager,
            coreDataManager: coreDataManager
        )
        
        let registerCoordinator = RegisterCoordinator(
            productManager: productManager,
            categoryManager: categoryManager,
            coreDataManager: coreDataManager
        )
        
        let stockCoordinator = StockCoordinator(
            productManager: productManager,
            categoryManager: categoryManager,
            coreDataManager: coreDataManager
        )
        
        let mainController = MainController(
            homeNavigationController: homeCoordinator.navigationController,
            registerNavigationController: registerCoordinator.navigationController,
            stockNavigationController: stockCoordinator.navigationController
        )
        window.rootViewController = mainController
        window.makeKeyAndVisible()
    }
}
