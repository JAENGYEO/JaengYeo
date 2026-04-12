//
//  AppCoordinator.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/7/26.
//

import UIKit

final class AppCoordinator {
    private let window: UIWindow
    private var syncManager: SyncManagerProtocol?
    private var childCoordinators: [Any] = []
    
    init(window: UIWindow) {
        self.window = window
    }
    
    func start() {
        let client = makeSupabaseClient()
        let productManager = ProductManager(client: client)
        let categoryManager = CategoryManager(client: client)
        let coreDataManager = CoreDataManager()
        
        try? coreDataManager.seedMockProductsIfNeeded()
        
        let syncManager = SyncManager(
            productManager: productManager,
            categoryManager: categoryManager,
            coreDataManager: coreDataManager
        )
        syncManager.networkCheck()
        self.syncManager = syncManager
        
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
        childCoordinators = [homeCoordinator, registerCoordinator, stockCoordinator]
        let mainController = MainController(
            homeNavigationController: homeCoordinator.navigationController,
            registerNavigationController: registerCoordinator.navigationController,
            stockNavigationController: stockCoordinator.navigationController
        )
        window.rootViewController = mainController
        window.makeKeyAndVisible()
    }
}
