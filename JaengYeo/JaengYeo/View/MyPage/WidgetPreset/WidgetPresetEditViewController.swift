//
//  WidgetPresetEditViewController.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/30/26.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import Then

protocol WidgetPresetEditViewControllerDelegate: AnyObject {
    func widgetPresetEditViewControllerDidRequestProductSelection(currentSelectedIDs: [UUID])
    func widgetPresetEditViewControllerDidSave()
    func widgetPresetEditViewControllerDidDelete()
}

final class WidgetPresetEditViewController: BaseViewController {

    private let viewModel: WidgetPresetEditViewModel
    private let mainView = WidgetPresetEditView()
    private let disposeBag = DisposeBag()

    private let saveButton = UIBarButtonItem(title: "저장", style: .plain, target: nil, action: nil)

    private let removeProductRelay = PublishRelay<UUID>()
    private let productSelectionResultRelay = PublishRelay<[UUID]>()
    private let deleteConfirmedRelay = PublishRelay<Void>()
    
    private lazy var dataSource = makeDataSource()

    weak var delegate: WidgetPresetEditViewControllerDelegate?

    init(viewModel: WidgetPresetEditViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = mainView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configNavigationBar()
        bind()
    }
}

extension WidgetPresetEditViewController {
    func didCompleteProductSelection(ids: [UUID]) {
        productSelectionResultRelay.accept(ids)
    }
}

extension WidgetPresetEditViewController {
    private func configNavigationBar() {
        navigationItem.rightBarButtonItem = saveButton
        saveButton.tintColor = .gray800
    }
}

extension WidgetPresetEditViewController {
    private func bind() {
        let input = WidgetPresetEditViewModel.Input(
            nameChanged: mainView.nameTextField.rx.text.orEmpty.asObservable(),
            addButtonTapped: mainView.addButton.rx.tap.asObservable(),
            removeProduct: removeProductRelay.asObservable(),
            saveButtonTapped: saveButton.rx.tap.asObservable(),
            deleteButtonTapped: deleteConfirmedRelay.asObservable(),
            productSelectionResult: productSelectionResultRelay.asObservable()
        )

        let output = viewModel.transform(input)

        output.title
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] in
                self?.title = $0
            })
            .disposed(by: disposeBag)

        output.initialName
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] in
                self?.mainView.nameTextField.text = $0
            })
            .disposed(by: disposeBag)

        output.isEditMode
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] isEdit in
                self?.mainView.updateDeleteButton(isVisible: isEdit)
            })
            .disposed(by: disposeBag)

        output.canSave
            .observe(on: MainScheduler.instance)
            .bind(to: saveButton.rx.isEnabled)
            .disposed(by: disposeBag)

        output.selectedProducts
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] products in
                self?.mainView.updateCountLabel(count: products.count)
                self?.applySnapshot(products: products)
            })
            .disposed(by: disposeBag)
        
        mainView.deleteButton.rx.tap
            .bind(onNext: { [weak self] in
                self?.showDeleteConfirmAlert()
            })
            .disposed(by: disposeBag)

        viewModel.navigateToProductSelection
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] currentIDs in
                self?.delegate?.widgetPresetEditViewControllerDidRequestProductSelection(currentSelectedIDs: currentIDs)
            })
            .disposed(by: disposeBag)

        viewModel.saveCompleted
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] in
                self?.delegate?.widgetPresetEditViewControllerDidSave()
            })
            .disposed(by: disposeBag)

        viewModel.deleteCompleted
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] in
                self?.delegate?.widgetPresetEditViewControllerDidDelete()
            })
            .disposed(by: disposeBag)
    }
}

extension WidgetPresetEditViewController {
    private func makeDataSource() -> UICollectionViewDiffableDataSource<WidgetPresetEditSection, WidgetPresetEditViewModel.SelectedProduct> {
        UICollectionViewDiffableDataSource(collectionView: mainView.collectionView) { [weak self] collectionView, indexPath, product in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: SelectedProductCell.id,
                for: indexPath
            ) as? SelectedProductCell else {
                return UICollectionViewCell()
            }
            cell.config(title: product.name, category: product.mainCategory)
            cell.bindRemoveButtonTap { [weak self] in
                self?.removeProductRelay.accept(product.id)
            }
            return cell
        }
    }

    private func applySnapshot(products: [WidgetPresetEditViewModel.SelectedProduct]) {
        var snapshot = NSDiffableDataSourceSnapshot<WidgetPresetEditSection, WidgetPresetEditViewModel.SelectedProduct>()
        snapshot.appendSections([.main])
        snapshot.appendItems(products, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

extension WidgetPresetEditViewController {
    private func showDeleteConfirmAlert() {
        AlertController.rx.alert(
            on: self,
            image: .alertRed,
            title: "프리셋 삭제",
            message: "이 프리셋을 삭제하시겠습니까?",
            actions: [.cancel("취소"), .destructive("삭제")]
        )
        .subscribe(onNext: { [weak self] action in
            if action.style == .destructive {
                self?.deleteConfirmedRelay.accept(())
            }
        })
        .disposed(by: disposeBag)
    }
}
