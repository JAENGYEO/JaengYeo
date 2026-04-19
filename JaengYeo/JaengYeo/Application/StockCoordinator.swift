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
    private weak var registerDetailViewController: RegisterDetailViewController?
    private var editingProductPayloads: [ObjectIdentifier: ProductPayload] = [:]
    
    private let productManager: ProductManagerProtocol
    private let categoryManager: CategoryManagerProtocol
    private let coreDataManager: CoreDataManagerProtocol
    
    init(productManager: ProductManagerProtocol, categoryManager: CategoryManagerProtocol, coreDataManager: CoreDataManagerProtocol) {
        self.productManager = productManager
        self.categoryManager = categoryManager
        self.coreDataManager = coreDataManager
        
        let viewController = StockViewController(viewModel: StockViewModel(coreDataManager: coreDataManager))
        self.stockViewController = viewController
        navigationController = BaseNavigationController(rootViewController: viewController)
        viewController.delegate = self
        navigationController.tabBarItem = UITabBarItem(
            title: "재고",
            image: UIImage(named: "bagIcon"),
            selectedImage: UIImage(named: "bagFillIcon")
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
    
    func didSelectProduct(productID: UUID) {
        let viewController = ProductDetailViewController(
            viewModel: ProductDetailViewModel(
                productID: productID,
                coreDataManager: coreDataManager
            )
        )
        viewController.delegate = self
        navigationController.pushViewController(viewController, animated: true)
    }
}

extension StockCoordinator: ProductDetailViewControllerDelegate {
    func productDetailViewController(
        _ viewController: ProductDetailViewController,
        didTapModify formData: RegisterFormData,
        originalPayload: ProductPayload
    ) {
        let viewController = RegisterDetailViewController(
            viewModel: RegisterDetailViewModel(item: formData)
        )
        viewController.delegate = self
        registerDetailViewController = viewController
        editingProductPayloads[ObjectIdentifier(viewController)] = originalPayload
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

extension StockCoordinator: RegisterDetailViewControllerDelegate {
    func didTapConfirmButton(
        _ viewController: RegisterDetailViewController,
        item: RegisterFormData
    ) {
        let identifier = ObjectIdentifier(viewController)
        guard let original = editingProductPayloads[identifier] else { return }
        editingProductPayloads[identifier] = nil

        let imageUrl: String?
        if let newImage = item.image {
            let fileName = "\(original.id.uuidString).jpg"
            guard let baseUrl = FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask).first
            else { return }

            let url = baseUrl.appendingPathComponent(fileName)
            if let data = newImage.jpegData(compressionQuality: 0.8) {
                try? data.write(to: url)
            }
            imageUrl = fileName
        } else {
            imageUrl = item.imageUrl ?? original.imageUrl
        }

        do {
            try coreDataManager.updateProduct(
                original.updated(with: item, imageUrl: imageUrl)
            )
        } catch {
            let alert = AlertController(
                image: UIImage(named: "alartRed") ?? UIImage(),
                title: "수정 실패",
                message: "상품 정보를 업데이트하는 중 오류가 발생했습니다.",
                actions: [.default("확인")]
            )
            navigationController.present(alert, animated: true)
        }
    }

    func didTapMidCategory(midCategory: UUID?) {
        guard let mainCategory = registerDetailViewController?.currentMainCategory else { return }
        let items = (try? coreDataManager.fetchAllMidCategories(mainCategory: mainCategory)) ?? []
        let selectionItems = items.map {
            CategorySelectionItem(
                id: $0.id.uuidString,
                title: $0.name,
                image: UIImage(named: $0.iconName ?? ""),
                isSelect: $0.id == midCategory
            )
        }

        let viewController = RegisterCategoryViewController(
            items: selectionItems,
            selectedID: midCategory?.uuidString
        )
        viewController.onSelect = { [weak self] selectedID in
            let selected = items.first { $0.id.uuidString == selectedID }
            self?.registerDetailViewController?.didSelectMidCategory(
                id: selected?.id,
                name: selected?.name
            )
        }
        navigationController.present(viewController, animated: false)
    }

    func didTapSubCategory(subCategory: UUID?) {
        guard let mainCategory = registerDetailViewController?.currentMainCategory else { return }
        let items = (try? coreDataManager.fetchAllSubCategories(mainCategory: mainCategory)) ?? []
        let selectionItems = items.map {
            CategorySelectionItem(
                id: $0.id.uuidString,
                title: $0.name,
                image: UIImage(named: $0.iconName ?? ""),
                isSelect: $0.id == subCategory
            )
        }

        let viewController = RegisterCategoryViewController(
            items: selectionItems,
            selectedID: subCategory?.uuidString
        )
        viewController.onSelect = { [weak self] selectedID in
            let selected = items.first { $0.id.uuidString == selectedID }
            self?.registerDetailViewController?.didSelectSubCategory(
                id: selected?.id,
                name: selected?.name,
                iconName: selected?.iconName
            )
        }
        navigationController.present(viewController, animated: false)
    }
}

extension StockCoordinator {
    func selectMainCategory(name: String) {
        stockViewController.selectMainCategory(name: name)
    }
}
