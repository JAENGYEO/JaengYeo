//
//  StockCoordinator.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/7/26.
//

import UIKit

final class StockCoordinator {
    let navigationController: UINavigationController
    private let stockViewController: StockViewController
    
    private let productManager: ProductManagerProtocol
    private let categoryManager: CategoryManagerProtocol
    private let coreDataManager: CoreDataManagerProtocol
    
    init(productManager: ProductManagerProtocol, categoryManager: CategoryManagerProtocol, coreDataManager: CoreDataManagerProtocol) {
        self.productManager = productManager
        self.categoryManager = categoryManager
        self.coreDataManager = coreDataManager
        
        let viewController = StockViewController(viewModel: StockViewModel(coreDataManager: coreDataManager))
        self.stockViewController = viewController
        navigationController = UINavigationController(rootViewController: viewController)
        viewController.delegate = self
        navigationController.tabBarItem = UITabBarItem(
            title: "재고",
            image: UIImage(systemName: "bag"),
            selectedImage: UIImage(systemName: "bag.fill")
        )
    }
}

extension StockCoordinator: StockViewControllerDelegate {
    func didTapCategoryEditButton() {
        let categoryEditViewController = CategoryEditViewController(
            viewModel: CategoryEditViewModel(coreDataManager: coreDataManager)
        )
        categoryEditViewController.delegate = self
        navigationController.pushViewController(categoryEditViewController, animated: true)
    }
    
    func didTapSearchButton() {
        let viewController = StockSearchViewController(
            viewModel: StockSearchViewModel(coreDataManager: coreDataManager)
        )
        navigationController.pushViewController(viewController, animated: true)
    }
}

extension StockCoordinator: CategoryEditViewControllerDelegate {
    func categoryEditViewController(
        _ viewController: CategoryEditViewController,
        didSelect mode: CategoryEditMode
    ) {
        let viewController = CategoryEditDetailViewController(
            mode: mode,
            viewModel: CategoryEditDetailViewModel(
                mode: mode,
                coreDataManager: coreDataManager
            )
        )
        navigationController.pushViewController(viewController, animated: true)
    }
}

extension StockCoordinator {
    func selectMainCategory(name: String) {
        stockViewController.selectMainCategory(name: name)
    }
}
