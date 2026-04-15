//
//  HomeCoordinator.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/7/26.
//

import UIKit
import RxSwift
import RxCocoa

final class HomeCoordinator {
    let navigationController: UINavigationController
    
    private let disposeBag = DisposeBag()
    
    private let productManager: ProductManagerProtocol
    private let categoryManager: CategoryManagerProtocol
    private let coreDataManager: CoreDataManagerProtocol
    
    let navigateToCategory = PublishSubject<String>()
    
    init(productManager: ProductManagerProtocol, categoryManager: CategoryManagerProtocol, coreDataManager: CoreDataManagerProtocol) {
        self.productManager = productManager
        self.categoryManager = categoryManager
        self.coreDataManager = coreDataManager
        
        let viewModel = HomeViewModel(coreDataManager: coreDataManager)
        let viewController = HomeViewController(viewModel: viewModel)
        navigationController = UINavigationController(rootViewController: viewController)
        navigationController.tabBarItem = UITabBarItem(
            title: "홈",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )
        
        viewModel.navigateToUnclassified
            .bind(onNext: { [weak self] _ in //TODO: Stock 이동 적용
                
            })
            .disposed(by: disposeBag)
        
        viewModel.navigateToCategory
            .bind(to: navigateToCategory)
            .disposed(by: disposeBag)
    }
}
