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
        
        let viewModel = CartViewModel(coreDataManager: coreDataManager)
        let viewController = CartViewController(viewModel: viewModel)
        navigationController = BaseNavigationController(rootViewController: viewController)
        viewController.delegate = self
        navigationController.tabBarItem = UITabBarItem(
            title: "장바구니",
            image: UIImage(named: "bagIcon"),
            selectedImage: UIImage(named: "bagFillIcon")
        )
    }
}

extension CartCoordinator: CartViewControllerDelegate {
    func didTapCartAddButton() {
        navigateToRegister.onNext(())
    }
}
