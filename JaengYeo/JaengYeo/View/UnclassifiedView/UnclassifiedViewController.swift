//
//  UnclassifiedViewController.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/15/26.
//

import UIKit
import RxSwift
import RxCocoa

final class UnclassifiedViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    private let viewModel: UnclassifiedViewModel
    private let mainView = UnclassifiedView()
    private var dataSource: UICollectionViewDiffableDataSource<Int, UnclassifiedViewModel.UnclassifiedItemSummary>?
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    private let viewWillAppearRelay = PublishRelay<Void>()
    
    init(viewModel: UnclassifiedViewModel) {
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
        configNavigationBar()
        configDataSource()
        bind()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearRelay.accept(())
    }
}

extension UnclassifiedViewController {
    private func bind() {
        let input = UnclassifiedViewModel.Input(
            viewWillAppear: viewWillAppearRelay.asObservable()
        )
        let output = viewModel.transform(input)
        output.items
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] items in
                self?.setSnapshot(items: items)
            })
            .disposed(by: disposeBag)
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

extension UnclassifiedViewController {
    private func configNavigationBar() {
        navigationItem.title = "미분류 상품"
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

extension UnclassifiedViewController {
    private func configDataSource() {
        dataSource = UICollectionViewDiffableDataSource(collectionView: mainView.collectionView) {collectionView, indexPath, itemIdentifier in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProductCell.id, for: indexPath) as? ProductCell else { return UICollectionViewCell() }
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
            cell.accessories = [.disclosureIndicator(options: .init(tintColor: .gray300))]
            return cell
        }
    }
}

extension UnclassifiedViewController {
    private func setSnapshot(items: [UnclassifiedViewModel.UnclassifiedItemSummary]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, UnclassifiedViewModel.UnclassifiedItemSummary>()
        snapshot.appendSections([0])
        snapshot.appendItems(items, toSection: 0)
        dataSource?.apply(snapshot, animatingDifferences: false)
    }
}
