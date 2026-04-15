//
//  AppCoordinator.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/7/26.
//

import UIKit
import Supabase
import RxSwift
import RxCocoa

final class AppCoordinator {
    private let window: UIWindow
    private var syncManager: SyncManagerProtocol?
    private var childCoordinators: [Any] = []
    private let disposeBag = DisposeBag()
    
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
        
        Task {
            _ = try? await client.auth.signIn(
                email: "test@test.com",
                password: "test1234"
            )
            if !UserDefaults.standard.bool(forKey: "firstLaunch") {
                for main in ["식재료", "생활용품"] {
                    if let mids = try? await categoryManager.fetchSystemMidCategories(mainCategory: main) {
                        for dto in mids {
                            try? coreDataManager.createMidCategory(dto.toPayload())
                        }
                    }
                    if let subs = try? await categoryManager.fetchSystemSubCategories(mainCategory: main) {
                        for dto in subs {
                            try? coreDataManager.createSubCategory(dto.toPayload())
                        }
                    }
                }
                UserDefaults.standard.set(true, forKey: "firstLaunch")
            }
            await MainActor.run {
                syncManager.networkCheck()
            }
        }
        self.syncManager = syncManager
        
        let homeCoordinator = HomeCoordinator(
            productManager: productManager,
            categoryManager: categoryManager,
            coreDataManager: coreDataManager
        )
        
        let registerCoordinator = RegisterCoordinator(
            productManager: productManager,
            categoryManager: categoryManager,
            coreDataManager: coreDataManager,
            syncManager: syncManager,
            client: client
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
        
        homeCoordinator.navigateToCategory
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak mainController, weak stockCoordinator] category in
                mainController?.selectedIndex = 2
                stockCoordinator?.selectMainCategory(name: category)
            })
            .disposed(by: disposeBag)
        
        registerCoordinator.navigateToStock
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak mainController] in
                mainController?.selectedIndex = 2
            })
            .disposed(by: disposeBag)
        
        window.rootViewController = mainController
        window.makeKeyAndVisible()

                  
    }
}
