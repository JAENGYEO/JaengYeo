//
//  StockCoordinator.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/7/26.
//

import UIKit

final class StockCoordinator {
    let navigationController: UINavigationController
    
    private let productManager: ProductManagerProtocol
    private let categoryManager: CategoryManagerProtocol
    private let coreDataManager: CoreDataManagerProtocol
    
    init(productManager: ProductManagerProtocol, categoryManager: CategoryManagerProtocol, coreDataManager: CoreDataManagerProtocol) {
        self.productManager = productManager
        self.categoryManager = categoryManager
        self.coreDataManager = coreDataManager
        
        let viewController = StockViewController(viewModel: StockViewModel(coreDataManager: coreDataManager))
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
}

extension StockCoordinator: CategoryEditViewControllerDelegate {
    func categoryEditViewController(
        _ viewController: CategoryEditViewController,
        didSelect mode: CategoryEditMode
    ) {
        let viewController = CategoryEditDetailViewController(mode: mode)
        navigationController.pushViewController(viewController, animated: true)
    }
}
