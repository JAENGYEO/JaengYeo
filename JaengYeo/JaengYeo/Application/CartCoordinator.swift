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
    let navigateToUnclassified = PublishSubject<Void>()
    private let coreDataManager: CoreDataManagerProtocol
    private let authManager: AuthManagerProtocol
    private weak var currentNavigationController: UINavigationController?
    
    init(coreDataManager: CoreDataManagerProtocol, authManager: AuthManagerProtocol) {
        self.coreDataManager = coreDataManager
        self.authManager = authManager
        
        let viewController = UIViewController()
        viewController.view.backgroundColor = .white
        navigationController = BaseNavigationController(rootViewController: viewController)
        navigationController.tabBarItem = UITabBarItem(
            title: "목록",
            image: UIImage(named: "List"),
            selectedImage: UIImage(named: "List")
        )
    }
}

extension CartCoordinator {
    /// 장바구니 화면 전환
    func pushCartViewController(from navigationController: UINavigationController) {
        guard !(navigationController.topViewController is CartViewController) else {
            return
        }
        currentNavigationController = navigationController

        let viewModel = CartViewModel(coreDataManager: coreDataManager)
        let viewController = CartViewController(viewModel: viewModel)
        viewController.delegate = self
        viewController.hidesBottomBarWhenPushed = true

        navigationController.pushViewController(viewController, animated: true)
    }
}

extension CartCoordinator: StockSearchViewControllerDelegate {
    func stockSearchViewController(
        _ viewController: StockSearchViewController,
        didSelectProduct productID: UUID
    ) {
        let viewController = ProductDetailViewController(
            viewModel: ProductDetailViewModel(
                productID: productID,
                coreDataManager: coreDataManager
            )
        )
        currentNavigationController?.pushViewController(viewController, animated: true)
    }
}

extension CartCoordinator: CartViewControllerDelegate {
    func didTapExistingProductButton() {
        let viewController = StockSearchViewController(
            viewModel: StockSearchViewModel(coreDataManager: coreDataManager)
        )
        viewController.delegate = self
        currentNavigationController?.pushViewController(viewController, animated: true)
    }

    func didTapNewProductButton() {
        let viewModel = CartAddItemViewModel(coreDataManager: coreDataManager)
        let viewController = CartAddItemViewController(viewModel: viewModel)
        currentNavigationController?.pushViewController(viewController, animated: true)
    }

    func didSelectCartItem(_ item: CartItem) {
        let viewModel = CartAddItemViewModel(
            coreDataManager: coreDataManager,
            item: item
        )
        let viewController = CartAddItemViewController(viewModel: viewModel)
        currentNavigationController?.pushViewController(viewController, animated: true)
    }

    func didTapConfirmButton(cartItems: [CartItem]) {
        let viewModel = PurchaseConfirmViewModel(
            cartItems: cartItems,
            coreDataManager: coreDataManager,
            authManager: authManager
        )
        let viewController = PurchaseConfirmViewController(viewModel: viewModel)
        viewController.delegate = self
        currentNavigationController?.pushViewController(viewController, animated: true)
    }
}

extension CartCoordinator: PurchaseConfirmViewControllerDelegate {
    func purchaseConfirmViewControllerDidFinishWithUnclassified(
        _ viewController: PurchaseConfirmViewController
    ) {
        currentNavigationController?.popToRootViewController(animated: false)
        navigateToUnclassified.onNext(())
    }
}
