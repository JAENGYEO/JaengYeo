//
//  CartCoordinator.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/28/26.
//

import UIKit
import RxSwift
import RxRelay

final class CartCoordinator {
    let navigationController: UINavigationController
    let navigateToRegister = PublishSubject<Void>()
    private let coreDataManager: CoreDataManagerProtocol
    private let authManager: AuthManagerProtocol
    
    init(coreDataManager: CoreDataManagerProtocol, authManager: AuthManagerProtocol) {
        self.coreDataManager = coreDataManager
        self.authManager = authManager
        
        let viewController = UIViewController()
        viewController.view.backgroundColor = .white
        navigationController = BaseNavigationController(rootViewController: viewController)
        navigationController.tabBarItem = UITabBarItem(
            title: "목록",
            image: UIImage(named: "list"),
            selectedImage: UIImage(named: "list")
        )
    }
}

extension CartCoordinator {
    /// 장바구니 화면 전환
    func pushCartViewController(from navigationController: UINavigationController) {
        guard !(navigationController.topViewController is CartViewController) else {
            return
        }

        let viewModel = CartViewModel(coreDataManager: coreDataManager)
        let viewController = CartViewController(viewModel: viewModel)
        viewController.delegate = self
        viewController.hidesBottomBarWhenPushed = true

        navigationController.pushViewController(viewController, animated: true)
    }
}

extension CartCoordinator: CartViewControllerDelegate {
    func didTapCartAddButton() {
        navigateToRegister.onNext(())
    }
}
