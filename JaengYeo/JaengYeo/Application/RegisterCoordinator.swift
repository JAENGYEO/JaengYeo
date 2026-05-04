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
import FoundationModels

final class RegisterCoordinator {
    let navigationController: UINavigationController
    
    private let productManager: ProductManagerProtocol
    private let categoryManager: CategoryManagerProtocol
    private let coreDataManager: CoreDataManagerProtocol
    private let syncManager: SyncManagerProtocol
    private let client: SupabaseClient
    private let authManager: AuthManagerProtocol

    
    private let disposeBag = DisposeBag()
    
    private weak var listViewModel: RegisterItemListViewModel?
    private weak var detailViewController: RegisterDetailViewController?
    private weak var registerViewController: RegisterViewController?
    
    let navigateToStock = PublishSubject<Void>()
    let navigateToHome = PublishSubject<Void>()
    
    init(productManager: ProductManagerProtocol, categoryManager: CategoryManagerProtocol, coreDataManager: CoreDataManagerProtocol, syncManager: SyncManagerProtocol, client: SupabaseClient, authManager: AuthManagerProtocol) {
        self.productManager = productManager
        self.categoryManager = categoryManager
        self.coreDataManager = coreDataManager
        self.syncManager = syncManager
        self.client = client
        self.authManager = authManager
        
        let parser: ReceiptProtocol
        if #available(iOS 26, *),
           SystemLanguageModel.default.availability == .available {
            parser = FoundationModelReceiptParser()
        } else {
            parser = AIReceiptParser(client: client)
        }
        let receiptAnalyzer = ReceiptAnalyzer(parser: parser)
        
        let viewModel = RegisterViewModel(client: client, receiptAnalyzer: receiptAnalyzer)
        let viewController = RegisterViewController(viewModel: viewModel)
        self.registerViewController = viewController
        navigationController = BaseNavigationController(rootViewController: viewController)
        navigationController.tabBarItem = UITabBarItem(
            title: "등록",
            image: UIImage(named: "cameraIcon"),
            selectedImage: UIImage(named: "cameraFillIcon")
        )
        viewController.delegate = self
    }
}

extension RegisterCoordinator: RegisterViewControllerDelegate {
    func pushItemListView(items: [RegisterFormData], pageTitle: String, infoLabel: String) {
        guard !navigationController.viewControllers.contains(where: { $0 is RegisterItemListViewController }) else { return }
        let viewModel = RegisterItemListViewModel(items: items, coreDataManager: coreDataManager, syncManager: syncManager, authManager: authManager)
        let viewController = RegisterItemListViewController(viewModel: viewModel, pageTitle: pageTitle, infoLabel: infoLabel)
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
        
        viewModel.navigateToStock
            .bind(onNext: { [weak self] in
                guard let self else { return }
                self.pushRegisterComplete()
            })
            .disposed(by: disposeBag)
        
        navigationController.pushViewController(viewController, animated: true)
    }
    
    func quickSave(items: [RegisterFormData]) -> Single<Int> {
        
        Single.create { [weak self] single in
            guard let self else { return Disposables.create() }
            guard let userId = authManager.currentUserId else {
                single(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "로그인이 필요합니다."])))
                return Disposables.create()
            }
            let now = Date()
            let payloads: [ProductPayload] = items.compactMap { item in
                guard let name = item.name, let mainCategory = item.mainCategory else { return nil }
                return ProductPayload(
                    id: item.id,
                    userId: userId,
                    name: name,
                    quantity: Int32(item.quantity ?? 1),
                    quantityUnit: item.quantityUnit,
                    mainCategory: mainCategory,
                    midCategoryId: nil,
                    subCategoryId: nil,
                    purchaseDate: nil,
                    expiryDate: nil,
                    price: 0,
                    locationMemo: nil,
                    memo: nil,
                    imageUrl: nil,
                    isClassified: false,
                    lowStockThreshold: nil,
                    isFavorite: false,
                    createdAt: now,
                    updatedAt: now,
                    syncStatus: SyncStatus.pendingUpload.rawValue,
                    isLowStockNotificationEnabled: false,
                    caution: nil,
                    brand: nil
                )
            }
            do {
                try coreDataManager.createProducts(payloads: payloads)
                syncManager.syncIfConnected()
                single(.success(payloads.count))
            } catch {
                single(.failure(error))
            }
            return Disposables.create()
        }
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
    func didTapConfirmButton(
        _ viewController: RegisterDetailViewController,
        item: RegisterFormData
    ) {
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
            CategorySelectionItem(id: $0.id.uuidString, title: $0.name, image: UIImage(named: $0.iconName ?? ""), isSelect: $0.id == midCategory)
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
            CategorySelectionItem(id: $0.id.uuidString, title: $0.name, image: UIImage(named: $0.iconName ?? ""), isSelect: $0.id == subCategory)
        }
        let viewController = RegisterCategoryViewController(items: selectionItem, selectedID: subCategory?.uuidString)
        viewController.onSelect = { [weak self] selectedID in
            let selectedItem = items.first { $0.id.uuidString == selectedID }
            self?.detailViewController?.didSelectSubCategory(id: selectedItem?.id, name: selectedItem?.name, iconName: selectedItem?.iconName)
        }
        navigationController.present(viewController, animated: false)
    }
}

extension RegisterCoordinator {
    func switchCameraMode(mode: CameraMode) {
        registerViewController?.pendingMode = mode
        navigationController.popToRootViewController(animated: true)
        registerViewController?.switchMode(mode: mode)
        
        if mode == .manual {
            pushItemListView(
                items: [],
                pageTitle: "직접 입력",
                infoLabel: "제품을 등록하고 쟁여를 시작해요!"
            )
            registerViewController?.pendingMode = nil
        }
    }
}

extension RegisterCoordinator {
    private func pushRegisterComplete() {
        let viewController = RegisterCompleteViewController()
        viewController.delegate = self
        navigationController.pushViewController(viewController, animated: true)
    }
}

extension RegisterCoordinator: RegisterCompleteViewControllerDelegate {
    func didTapStockButton() {
        navigationController.setViewControllers(Array(navigationController.viewControllers.prefix(1)), animated: false)
        navigateToStock.onNext(())
    }
    func didTapHomeButton() {
        navigationController.setViewControllers(Array(navigationController.viewControllers.prefix(1)), animated: false)
        navigateToHome.onNext(())
    }
}
