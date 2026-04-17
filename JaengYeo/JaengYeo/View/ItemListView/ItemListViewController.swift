//
//  ItemListViewController.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/17/26.
//

import UIKit
import RxSwift
import RxCocoa

final class ItemListViewController: UIViewController {
    private let disposeBag = DisposeBag()
    private let viewModel: ItemListViewModel
    private let mainView = ItemListView()
    private var dataSource: UICollectionViewDiffableDataSource<Int, ItemListViewModel.ItemSummary>?
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    private let viewWillAppearRelay = PublishRelay<Void>()
    
    init(viewModel: ItemListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = mainView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mainView.infoLabel.text = viewModel.listType.info
        configNavigationBar()
        configDataSource()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearRelay.accept(())
    }
}

extension ItemListViewController {
    private func bind() {
        let input = ItemListViewModel.Input(viewWillAppear: viewWillAppearRelay.asObservable())
        let output = viewModel.transform(input)
        
        output.items
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] items in
                self?.setSnapshot(items: items)
            })
            .disposed(by: disposeBag)
        
        if case .unclassified = viewModel.listType {
            mainView.collectionView.rx.itemSelected
                .compactMap { [weak self] indexPath in
                    self?.dataSource?.itemIdentifier(for: indexPath)
                }
                .bind(onNext: { [weak self] item in
                    self?.viewModel.navigateToDetail.onNext(item.id)
                })
                .disposed(by: disposeBag)
        }
    }
}

extension ItemListViewController {
    private func configNavigationBar() {
        navigationItem.title = viewModel.listType.title
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.titleTextAttributes = [
            .font: LabelConfiguration.titleSemi18.font,
            .foregroundColor: UIColor.gray800
        ]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .gray800
    }
}

extension ItemListViewController {
    private func configDataSource() {
        dataSource = UICollectionViewDiffableDataSource(collectionView: mainView.collectionView) { [weak self] collectionView, indexPath, itemIdentifier in
            guard let self,
                  let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProductCell.id, for: indexPath) as? ProductCell else {
                return UICollectionViewCell()
            }
            switch self.viewModel.listType {
            case .unclassified:
                let dateString = self.dateFormatter.string(from: itemIdentifier.createdAt)
                cell.updateUI(
                    type: .unclassifiedType,
                    title: itemIdentifier.name,
                    freshness: nil,
                    descriptions: ["\(dateString) 등록", "\(itemIdentifier.quantity)개"],
                    subdescriptions: nil,
                    count: nil,
                    image: itemIdentifier.image ?? itemIdentifier.subCategoryIconName.flatMap { UIImage(systemName: $0) }
                )
                cell.accessories = [.disclosureIndicator(options: .init(tintColor: .gray300)) ]
            case .expiryImminent(let day):
                cell.updateUI(
                    type: .unclassifiedType,
                    title: itemIdentifier.name,
                    freshness: itemIdentifier.expiryDaysLeft,
                    descriptions: ["\(itemIdentifier.quantity)개"],
                    subdescriptions: nil,
                    count: nil,
                    image: itemIdentifier.image ?? itemIdentifier.subCategoryIconName.flatMap { UIImage(systemName: $0) }
                )
            case .lowStock:
                cell.updateUI(
                    type: .unclassifiedType,
                    title: itemIdentifier.name,
                    freshness: nil,
                    descriptions: ["재고 \(itemIdentifier.quantity)개"],
                    subdescriptions: nil,
                    count: nil,
                    image: itemIdentifier.image ?? itemIdentifier.subCategoryIconName.flatMap { UIImage(systemName: $0) }
                )
            }
            return cell
        }
    }
}

extension ItemListViewController {
    private func setSnapshot(items: [ItemListViewModel.ItemSummary]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, ItemListViewModel.ItemSummary>()
        snapshot.appendSections([0])
        snapshot.appendItems(items, toSection: 0)
        dataSource?.apply(snapshot, animatingDifferences: false)
    }
}
