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
    let navigateToRegister = PublishSubject<Void>()
    
    private var currentProductPayload: ProductPayload?
    private weak var currentDetailViewController: RegisterDetailViewController?
    
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
            .bind(onNext: { [weak self] _ in
                self?.pushItemList(type: .unclassified)
            })
            .disposed(by: disposeBag)
        
        viewModel.navigateToCategory
            .bind(to: navigateToCategory)
            .disposed(by: disposeBag)
        
        viewModel.navigateToRegister
            .bind(to: navigateToRegister)
            .disposed(by: disposeBag)
        
        viewModel.navigateToExpiryImminent
            .bind(onNext: { [weak self] _ in
                self?.pushItemList(type: .expiryImminent(day: 1))
            })
            .disposed(by: disposeBag)
        
        viewModel.navigateToLowStock
            .bind(onNext: { [weak self] _ in
                self?.pushItemList(type: .lowStock)
            })
            .disposed(by: disposeBag)
        
        NotificationManager.shared.notificationTapped
            .bind(onNext: { [weak self] type in
                self?.pushItemList(type: type)
            })
            .disposed(by: disposeBag)
        
    }
}

extension HomeCoordinator {
    private func pushItemList(type: ItemListType) {
        let viewModel = ItemListViewModel(coreDataManager: coreDataManager, listType: type)
        let viewController = ItemListViewController(viewModel: viewModel)
        
        if case .unclassified = type {
            viewModel.navigateToDetail
                .bind(onNext: { [weak self] id in
                    self?.pushUnclassifiedDetail(id: id)
                })
                .disposed(by: disposeBag)
        }
        navigationController.pushViewController(viewController, animated: true)
    }
    
    private func pushUnclassifiedDetail(id: UUID) {
        guard let payload = try? coreDataManager.fetchProduct(of: id) else { return }
        currentProductPayload = payload

        let midCategoryName = payload.midCategoryId.flatMap { try? coreDataManager.fetchMidCategory(of: $0).name }
        let subCategoryData = payload.subCategoryId.flatMap { try? coreDataManager.fetchSubCategory(of: $0) }
        let form = payload.toRegisterFormData(midCategoryName: midCategoryName, subCategoryData: subCategoryData)

        let detailViewModel = RegisterDetailViewModel(item: form)
        let detailViewController = RegisterDetailViewController(viewModel: detailViewModel)
        detailViewController.delegate = self
        currentDetailViewController = detailViewController
        navigationController.pushViewController(detailViewController, animated: true)
    }
}

extension HomeCoordinator: RegisterDetailViewControllerDelegate {
    func didTapConfirmButton(
        _ viewController: RegisterDetailViewController,
        item: RegisterFormData
    ) {
        guard let original = currentProductPayload else { return }

        let imageUrl: String?
        if let newImage = item.image {
            let fileName = "\(original.id.uuidString).jpg"
            guard let baseUrl = FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask).first else { return }
                let url = baseUrl.appendingPathComponent(fileName)
            if let data = newImage.jpegData(compressionQuality: 0.8) {
                try? data.write(to: url)
            }
            imageUrl = fileName
        } else {
            imageUrl = item.imageUrl ?? original.imageUrl
        }
        do {
            try coreDataManager.updateProduct(original.updated(with: item, imageUrl: imageUrl))
        } catch {
            //TODO: 에러처리 필요
        }
    }
    
    func didTapMidCategory(midCategory: UUID?) {
        guard let mainCategory = currentDetailViewController?.currentMainCategory else { return }
        let items = (try? coreDataManager.fetchAllMidCategories(mainCategory: mainCategory)) ?? []
        let selectionItems = items.map {
            CategorySelectionItem(
                id: $0.id.uuidString,
                title: $0.name,
                image: nil,
                isSelect: $0.id == midCategory
            )
        }
        let viewController = RegisterCategoryViewController(items: selectionItems, selectedID: midCategory?.uuidString)
        viewController.onSelect = { [weak self] selectedID in
            let selected = items.first { $0.id.uuidString == selectedID }
            self?.currentDetailViewController?.didSelectMidCategory(
                id: selected?.id,
                name: selected?.name
            )
        }
        navigationController.present(viewController, animated: false)
    }
    
    func didTapSubCategory(subCategory: UUID?) {
        guard let mainCategory = currentDetailViewController?.currentMainCategory else { return }
        let items = (try? coreDataManager.fetchAllSubCategories(mainCategory: mainCategory)) ?? []
        let selectionItems = items.map {
            CategorySelectionItem(
                id: $0.id.uuidString,
                title: $0.name,
                image: nil,
                isSelect: $0.id == subCategory
            )
        }
        let viewController = RegisterCategoryViewController(items: selectionItems, selectedID: subCategory?.uuidString)
        viewController.onSelect = { [weak self] selectedID in
            let selected = items.first { $0.id.uuidString == selectedID }
            self?.currentDetailViewController?.didSelectSubCategory(id: selected?.id, name: selected?.name, iconName: selected?.iconName)
        }
        navigationController.present(viewController, animated: false)
    }
}
