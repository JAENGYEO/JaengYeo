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
    private let syncManager: SyncManagerProtocol
    private let client: SupabaseClient

    
    private let disposeBag = DisposeBag()
    
    private weak var listViewModel: RegisterItemListViewModel?
    private weak var detailViewController: RegisterDetailViewController?
    
    init(productManager: ProductManagerProtocol, categoryManager: CategoryManagerProtocol, coreDataManager: CoreDataManagerProtocol, syncManager: SyncManagerProtocol, client: SupabaseClient) {
        self.productManager = productManager
        self.categoryManager = categoryManager
        self.coreDataManager = coreDataManager
        self.syncManager = syncManager
        self.client = client
        
        let parser: ReceiptProtocol
        if #available(iOS 26, *) {
            parser = FoundationModelReceiptParser()
        } else {
            parser = AIReceiptParser(client: client)
        }
        let receiptAnalyzer = ReceiptAnalyzer(parser: parser)
        
        let viewModel = RegisterViewModel(client: client, receiptAnalyzer: receiptAnalyzer)
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
    func pushItemListView(items: [RegisterFormData], pageTitle: String, showInfoLabel: Bool = true) {
        let viewModel = RegisterItemListViewModel(items: items, coreDataManager: coreDataManager, syncManager: syncManager)
        let viewController = RegisterItemListViewController(viewModel: viewModel, pageTitle: pageTitle, showInfoLabel: showInfoLabel)
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
        detailViewController = viewController
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
    
    func didTapMidCategory(midCategory: UUID?) {
        guard let mainCategory = detailViewController?.currentMainCategory else { return }
        let items = (try? coreDataManager.fetchAllMidCategories(mainCategory: mainCategory)) ?? []
        let selectionItem = items.map {
            CategorySelectionItem(id: $0.id.uuidString, title: $0.name, image: nil, isSelect: $0.id == midCategory)
        }
        let viewController = RegisterCategoryViewController(items: selectionItem, selectedID: midCategory?.uuidString)
        viewController.onSelect = { [weak self] selectedID in
            let selectedItem = items.first { $0.id.uuidString == selectedID }
            self?.detailViewController?.didSelectMidCategory(id: selectedItem?.id, name: selectedItem?.name)
        }
        navigationController.present(viewController, animated: false)
    }
    
    func didTapSubCategory(subCategory: UUID?) {
        guard let mainCategory = detailViewController?.currentMainCategory else { return }
        let items = (try? coreDataManager.fetchAllSubCategories(mainCategory: mainCategory)) ?? []
        let selectionItem = items.map {
            CategorySelectionItem(id: $0.id.uuidString, title: $0.name, image: nil, isSelect: $0.id == subCategory)
        }
        let viewController = RegisterCategoryViewController(items: selectionItem, selectedID: subCategory?.uuidString)
        viewController.onSelect = { [weak self] selectedID in
            let selectedItem = items.first { $0.id.uuidString == selectedID }
            self?.detailViewController?.didSelectSubCategory(id: selectedItem?.id, name: selectedItem?.name, iconName: selectedItem?.iconName)
        }
        navigationController.present(viewController, animated: false)
    }
}
