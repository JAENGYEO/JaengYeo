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
    
    private weak var listViewModel: RegisterItemListViewModel?
    
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
        let viewModel = RegisterItemListViewModel(items: items, coreDataManager: coreDataManager)
        let viewController = RegisterItemListViewController(viewModel: viewModel, pageTitle: "AI 인식 결과")
        listViewModel = viewModel
        viewModel.navigateToAdd
            .bind(onNext: { [weak self] in
                self?.pushRegisterDetailView(item: RegisterFormData())
            })
            .disposed(by: disposeBag)
        
        viewModel.navigateToDetail
            .bind(onNext: { [weak self] item in
                self?.pushRegisterDetailView(item: item)
            })
            .disposed(by: disposeBag)
        
        navigationController.pushViewController(viewController, animated: true)
    }
}

extension RegisterCoordinator {
    func pushRegisterDetailView(item: RegisterFormData) {
        let viewModel = RegisterDetailViewModel(item: item)
        let viewController = RegisterDetailViewController(viewModel: viewModel)
        viewController.delegate = self
        navigationController.pushViewController(viewController, animated: true)
    }
}

extension RegisterCoordinator: RegisterDetailViewControllerDelegate {
    func didTapConfirmButton(item: RegisterFormData) {
        if listViewModel?.hasItem(id: item.id) == true {
            listViewModel?.updateItem(item: item)
        } else {
            listViewModel?.appendItem(item: item)
        }
    }
}
