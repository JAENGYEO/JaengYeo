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
    private let authManager: AuthManagerProtocol
    
    let navigateToCategory = PublishSubject<String>()
    let navigateToRegister = PublishSubject<Void>()
    let logoutCompleted = PublishSubject<Void>()
    
    private var currentProductPayload: ProductPayload?
    private weak var currentDetailViewController: RegisterDetailViewController?
    
    init(productManager: ProductManagerProtocol, categoryManager: CategoryManagerProtocol, coreDataManager: CoreDataManagerProtocol, authManager: AuthManagerProtocol) {
        self.productManager = productManager
        self.categoryManager = categoryManager
        self.coreDataManager = coreDataManager
        self.authManager = authManager
        
        let viewModel = HomeViewModel(coreDataManager: coreDataManager)
        let viewController = HomeViewController(viewModel: viewModel)
        navigationController = BaseNavigationController(rootViewController: viewController)
        viewController.delegate = self
        navigationController.tabBarItem = UITabBarItem(
            title: "홈",
            image: UIImage(named: "homeIcon"),
            selectedImage: UIImage(named: "homeFillIcon")
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
        
        viewModel.navigateToProductDetail
            .bind(onNext: { [weak self] productId in
                self?.pushProductDetail(productId: productId)
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
    /// 미분류 목록 화면 전환
    func pushUnclassifiedList() {
        navigationController.popToRootViewController(animated: false)
        pushItemList(type: .unclassified)
    }

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
    
    private func pushMyPage() {
        let viewController = MyPageViewController(
            viewModel: MyPageViewModel(authManager: authManager, coreDataManager: coreDataManager)
        )
        viewController.delegate = self
        navigationController.pushViewController(viewController, animated: true)
    }
    
    private func pushProductDetail(productId: UUID) {
        let viewController = ProductDetailViewController(
            viewModel: ProductDetailViewModel(
                productID: productId,
                coreDataManager: coreDataManager
            )
        )
        viewController.delegate = self
        navigationController.pushViewController(viewController, animated: true)
    }
}

extension HomeCoordinator: HomeViewControllerDelegate {
    func didTapMyPageButton() {
        pushMyPage()
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

extension HomeCoordinator: MyPageViewControllerDelegate {
    func didLogout() {
        logoutCompleted.onNext(())
    }
}

extension HomeCoordinator: ProductDetailViewControllerDelegate {
    func productDetailViewController(_ viewController: ProductDetailViewController, didTapModify formData: RegisterFormData, originalPayload: ProductPayload) {
        currentProductPayload = originalPayload
        let viewModel = RegisterDetailViewModel(item: formData)
        let viewController = RegisterDetailViewController(viewModel: viewModel)
        viewController.delegate = self
        currentDetailViewController = viewController
        navigationController.pushViewController(viewController, animated: true)
    }
}
