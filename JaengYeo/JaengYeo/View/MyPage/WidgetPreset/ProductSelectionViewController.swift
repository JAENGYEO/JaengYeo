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
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
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

        mainView.backButton.rx.tap
            .bind(onNext: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)

        let viewWillAppear = rx.methodInvoked(#selector(viewWillAppear(_:)))
            .map { _ in }
        
        let searchKeyword = mainView.searchBar.rx.text.orEmpty
            .debounce(.milliseconds(200), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .asObservable()

        let input = ProductSelectionViewModel.Input(
            viewWillAppear: viewWillAppear,
            itemTapped: itemTappedRelay.asObservable(),
            confirmButtonTapped: mainView.confirmButton.rx.tap.asObservable(),
            searchKeyword: searchKeyword
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
                self?.mainView.counterLabel.text = text
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
                withReuseIdentifier: ProductCell.id,
                for: indexPath
            ) as? ProductCell else {
                return UICollectionViewCell()
            }
            var descriptions: [String] = []
            if let midCategory = item.midCategoryName { descriptions.append(midCategory) }
            if let subCategory = item.subCategoryName { descriptions.append(subCategory) }
            cell.updateUI(
                type: .detailType,
                title: item.name,
                freshness: item.expiryDaysLeft,
                descriptions: descriptions,
                subdescriptions: nil,
                count: item.quantity,
                image: item.image ?? item.subCategoryIconName.flatMap { UIImage(named: $0) }
            )
            var bgConfig = cell.backgroundConfiguration ?? UIBackgroundConfiguration.clear()
            bgConfig.strokeColor = .gray100
            bgConfig.strokeWidth = 1
            cell.backgroundConfiguration = bgConfig
            let checkImage = UIImageView().then {
                $0.image = UIImage(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                $0.tintColor = item.isSelected ? .accent : .gray300
                $0.contentMode = .scaleAspectFit
                $0.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
            }
            let checkConfig = UICellAccessory.CustomViewConfiguration(
                customView: checkImage,
                placement: .leading(displayed: .always)
            )
            cell.accessories = [.customView(configuration: checkConfig)]
            cell.contentView.alpha = item.isEnabled ? 1 : 0.4
            cell.isUserInteractionEnabled = item.isEnabled
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
