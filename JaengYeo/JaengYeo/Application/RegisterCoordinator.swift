//
//  RegisterCoordinator.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/7/26.
//

import UIKit
import Supabase
import RxSwift
import RxCocoa

final class RegisterCoordinator {
    let navigationController: UINavigationController
    
    private let productManager: ProductManagerProtocol
    private let categoryManager: CategoryManagerProtocol
    private let coreDataManager: CoreDataManagerProtocol
    private let client: SupabaseClient
    
    private let disposeBag = DisposeBag()
    
    private weak var listViewController: RegisterItemListViewController?
    
    init(productManager: ProductManagerProtocol, categoryManager: CategoryManagerProtocol, coreDataManager: CoreDataManagerProtocol, client: SupabaseClient) {
        self.productManager = productManager
        self.categoryManager = categoryManager
        self.coreDataManager = coreDataManager
        self.client = client
        
        let viewModel = RegisterViewModel(client: client)
        let viewController = RegisterViewController(viewModel: viewModel)
        navigationController = UINavigationController(rootViewController: viewController)
        navigationController.tabBarItem = UITabBarItem(
            title: "등록",
            image: UIImage(systemName: "camera"),
            selectedImage: UIImage(systemName: "camera.fill")
        )
        viewController.delegate = self
    }
}

extension RegisterCoordinator: RegisterViewControllerDelegate {
    func pushItemListView(items: [RegisterFormData]) {
        let viewController = RegisterItemListViewController(items: items, pageTitle: "AI 인식 결과")
        viewController.delegate = self
        listViewController = viewController
        viewController.addButtonTapped
            .bind(onNext: { [weak self] in
                self?.pushRegisterDetailView(item: RegisterFormData())
            })
            .disposed(by: disposeBag)
        navigationController.pushViewController(viewController, animated: true)
    }
}

extension RegisterCoordinator: RegisterItemListViewControllerDelegate {
    func pushRegisterDetailView(item: RegisterFormData) {
        let viewController = RegisterDetailViewController(item: item)
        viewController.delegate = self
        navigationController.pushViewController(viewController, animated: true)
    }
    
    func saveItems(items: [RegisterFormData]) {
        
    }
}

extension RegisterCoordinator: RegisterDetailViewControllerDelegate {
    func didTapConfirmButton(item: RegisterFormData) {
        if listViewController?.hasItem(id: item.id) == true {
            listViewController?.updateItem(item: item)
        } else {
            listViewController?.appendItem(item: item)
        }
    }
}
