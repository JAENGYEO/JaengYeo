//
//  ProductSelectionViewController.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/30/26.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import Then

protocol ProductSelectionViewControllerDelegate: AnyObject {
    func productSelectionViewController(_ viewController: ProductSelectionViewController, didConfirmWith ids: [UUID])
}

final class ProductSelectionViewController: BaseViewController {

    private let viewModel: ProductSelectionViewModel
    private let mainView = ProductSelectionView()
    private let disposeBag = DisposeBag()

    private let itemTappedRelay = PublishRelay<UUID>()

    private lazy var dataSource = makeDataSource()

    weak var delegate: ProductSelectionViewControllerDelegate?

    init(viewModel: ProductSelectionViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
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

extension ProductSelectionViewController {
    private func configNavigationBar() {
        title = "상품 선택"
    }
}

extension ProductSelectionViewController {
    private func bind() {
        let itemSelected = mainView.collectionView.rx.itemSelected
            .compactMap { [weak self] indexPath -> UUID? in
                guard let item = self?.dataSource.itemIdentifier(for: indexPath) else { return nil }
                return item.id
            }
            .do(onNext: { [weak self] _ in
                if let indexPath = self?.mainView.collectionView.indexPathsForSelectedItems?.first {
                    self?.mainView.collectionView.deselectItem(at: indexPath, animated: false)
                }
            })

        itemSelected
            .bind(to: itemTappedRelay)
            .disposed(by: disposeBag)

        let viewWillAppear = rx.methodInvoked(#selector(viewWillAppear(_:)))
            .map { _ in }

        let input = ProductSelectionViewModel.Input(
            viewWillAppear: viewWillAppear,
            itemTapped: itemTappedRelay.asObservable(),
            confirmButtonTapped: mainView.confirmButton.rx.tap.asObservable()
        )

        let output = viewModel.transform(input)

        output.items
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] items in
                self?.applySnapshot(items: items)
            })
            .disposed(by: disposeBag)

        output.counterText
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] text in
                self?.navigationItem.rightBarButtonItem = UIBarButtonItem(title: text, style: .plain, target: nil, action: nil)
                self?.navigationItem.rightBarButtonItem?.isEnabled = false
                self?.navigationItem.rightBarButtonItem?.tintColor = .gray500
            })
            .disposed(by: disposeBag)

        viewModel.confirmCompleted
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] ids in
                guard let self else { return }
                self.delegate?.productSelectionViewController(self, didConfirmWith: ids)
            })
            .disposed(by: disposeBag)
    }
}

extension ProductSelectionViewController {
    private func makeDataSource() -> UICollectionViewDiffableDataSource<ProductSelectionSection, ProductSelectionViewModel.ProductItem> {
        UICollectionViewDiffableDataSource(collectionView: mainView.collectionView) { collectionView, indexPath, item in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ProductSelectionCell.id,
                for: indexPath
            ) as? ProductSelectionCell else {
                return UICollectionViewCell()
            }
            cell.config(
                title: item.name,
                category: item.mainCategory,
                isSelected: item.isSelected,
                isEnabled: item.isEnabled
            )
            return cell
        }
    }

    private func applySnapshot(items: [ProductSelectionViewModel.ProductItem]) {
        var snapshot = NSDiffableDataSourceSnapshot<ProductSelectionSection, ProductSelectionViewModel.ProductItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}
