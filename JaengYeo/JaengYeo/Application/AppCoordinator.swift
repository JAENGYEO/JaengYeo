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

private enum Tab: Int {
    case home = 0
    case register = 1
    case stock = 2
}

final class AppCoordinator {
    private enum UserDefaultsKey {
        static let firstLaunch = "firstLaunch"
        static let hasSeenOnboarding = "hasSeenOnboarding"
    }

    private let window: UIWindow
    private let client: SupabaseClient
    private let authManager: AuthManagerProtocol
    private var syncManager: SyncManagerProtocol?
    private var childCoordinators: [Any] = []
    private let disposeBag = DisposeBag()
    
    init(window: UIWindow) {
        self.window = window
        self.client = makeSupabaseClient()
        self.authManager = AuthManager(client: client)
    }
    
    func start() {
        window.makeKeyAndVisible()
        
        Task {
            await authManager.clearSessionIfReinstalled()
            let hasSession = await authManager.restoreSession()
            await MainActor.run {
                if hasSession {
                    routeToInitialScreen()
                } else {
                    showLogin()
                }
            }
        }
    }

    private func routeToInitialScreen() {
        if UserDefaults.standard.bool(forKey: UserDefaultsKey.hasSeenOnboarding) {
            showMain()
        } else {
            showOnboarding()
        }
    }
    
    private func showLogin() {
        let viewModel = LoginViewModel(authManager: authManager)
        let viewController = LoginViewController(viewModel: viewModel)
        let navigationController = BaseNavigationController(rootViewController: viewController)
        navigationController.setNavigationBarHidden(true, animated: true)
        
        viewModel.loginCompleted
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] in
                self?.routeToInitialScreen()
            })
            .disposed(by: disposeBag)
        
        window.rootViewController = navigationController
    }

    private func showOnboarding() {
        let viewController = OnboardingViewController()
        viewController.delegate = self

        let navigationController = BaseNavigationController(rootViewController: viewController)
        navigationController.setNavigationBarHidden(true, animated: false)
        window.rootViewController = navigationController
    }
    
    private func showMain() {
        
        let productManager = ProductManager(client: client)
        let categoryManager = CategoryManager(client: client, authManager: authManager)
        let coreDataManager = CoreDataManager()
        
        let syncManager = SyncManager(
            productManager: productManager,
            categoryManager: categoryManager,
            coreDataManager: coreDataManager
        )
        
        Task {
            if !UserDefaults.standard.bool(forKey: UserDefaultsKey.firstLaunch) {
                var allSuccess = true
                for main in ["식재료", "생활용품"] {
                    if let mids = try? await categoryManager.fetchSystemMidCategories(mainCategory: main) {
                        for dto in mids {
                            do {
                                try await MainActor.run {
                                    try coreDataManager.createMidCategory(dto.toPayload())
                                }
                            } catch {
                                allSuccess = false
                            }
                        }
                    } else {
                        allSuccess = false
                    }
                    if let subs = try? await categoryManager.fetchSystemSubCategories(mainCategory: main) {
                        for dto in subs {
                            do {
                                try await MainActor.run {
                                    try coreDataManager.createSubCategory(dto.toPayload())
                                }
                            } catch {
                                allSuccess = false
                            }
                        }
                    } else {
                        allSuccess = false
                    }
                }
                if allSuccess {
                    UserDefaults.standard.set(true, forKey: UserDefaultsKey.firstLaunch)
                }
            }
            await MainActor.run {
                syncManager.networkCheck()
            }
        }
        self.syncManager = syncManager
        NotificationManager.shared.config(client: client)
        
        let homeCoordinator = HomeCoordinator(
            productManager: productManager,
            categoryManager: categoryManager,
            coreDataManager: coreDataManager,
            authManager: authManager
        )
        
        let registerCoordinator = RegisterCoordinator(
            productManager: productManager,
            categoryManager: categoryManager,
            coreDataManager: coreDataManager,
            syncManager: syncManager,
            client: client,
            authManager: authManager
        )
        
        let stockCoordinator = StockCoordinator(
            productManager: productManager,
            categoryManager: categoryManager,
            coreDataManager: coreDataManager,
            authManager: authManager
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
                mainController?.selectedIndex = Tab.stock.rawValue
                stockCoordinator?.selectMainCategory(name: category)
            })
            .disposed(by: disposeBag)
        
        homeCoordinator.navigateToRegister
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak mainController] in
                mainController?.selectedIndex = Tab.register.rawValue
            })
            .disposed(by: disposeBag)
        
        homeCoordinator.logoutCompleted
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] in
                self?.showLogin()
            })
            .disposed(by: disposeBag)
        
        registerCoordinator.navigateToStock
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak mainController] in
                mainController?.selectedIndex = Tab.stock.rawValue
            })
            .disposed(by: disposeBag)
        
        stockCoordinator.navigateToRegister
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak mainController] in
                mainController?.selectedIndex = Tab.register.rawValue
            })
            .disposed(by: disposeBag)
        
        window.rootViewController = mainController
    }
}

extension AppCoordinator: OnboardingViewControllerDelegate {
    func didTapOnboardingStartButton() {
        UserDefaults.standard.set(true, forKey: UserDefaultsKey.hasSeenOnboarding)
        showMain()
    }
}

extension AppCoordinator {
    func handle(deepLink: DeepLink) {
        switch deepLink {
        case .product(let id):
            break
        case .confirmDelete(let id):
            break
        case .lowStockList:
            break
        case .expiryList:
            break
        case .camera(let mode):
            break
        case .widgetSettings:
            break
        }
    }
}
