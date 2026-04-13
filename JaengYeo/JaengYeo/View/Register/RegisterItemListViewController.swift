//
//  RegisterItemListViewController.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/10/26.
//

import UIKit
import RxSwift
import RxCocoa

final class RegisterItemListViewController: UIViewController {
    
    typealias SectionID = UUID
    
    private let disposeBag = DisposeBag()
    private let mainView = RegisterItemListView()
    private let viewModel: RegisterItemListViewModel
    private let pageTitle: String
    
    private let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
    
    init(viewModel: RegisterItemListViewModel, pageTitle: String) {
        self.viewModel = viewModel
        self.pageTitle = pageTitle
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var dataSource: UICollectionViewDiffableDataSource<SectionID, RegisterFormData> = {
        return UICollectionViewDiffableDataSource<SectionID, RegisterFormData>(collectionView: mainView.collectionView) { collectionView, indexPath, itemIdentifier in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProductCell.productCellID, for: indexPath) as? ProductCell else { return UICollectionViewCell() }
            cell.updateUI(
                type: ProductCellType.registType,
                title: itemIdentifier.name ?? "정보 없음",
                freshness: nil,
                descriptions: [itemIdentifier.mainCategory].compactMap { $0 },
                subdescriptions: nil,
                count: itemIdentifier.quantity
            )
            cell.accessories = [.disclosureIndicator(options: .init(tintColor: .gray300))]
            return cell
        }
    }()
    
    override func loadView() {
        self.view = mainView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mainView.collectionView.register(ProductCell.self, forCellWithReuseIdentifier: ProductCell.productCellID)
        configNavigationBar()
        bind()
    }
}

extension RegisterItemListViewController {
    private func bind() {
        
        let cellTapped = mainView.collectionView.rx.itemSelected
            .do(onNext: { [weak self] indexPath in
                self?.mainView.collectionView.deselectItem(at: indexPath, animated: true)
            })
            .compactMap { [weak self] indexPath in
                self?.dataSource.itemIdentifier(for: indexPath)
            }
            .asObservable()
        
        let input = RegisterItemListViewModel.Input(
            saveButtonTapped: mainView.saveButton.rx.tap.asObservable(),
            addButtonTapped: addButton.rx.tap.asObservable(),
            cellTapped: cellTapped
        )
        
        let output = viewModel.transform(input)
        
        output.items
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] items in
                self?.setSnapshot(items: items)
            })
            .disposed(by: disposeBag)
        
        output.error
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] error in
                self?.showErrorAlert(title: "에러", message: error)
            })
            .disposed(by: disposeBag)
    }
}

extension RegisterItemListViewController {
    private func configNavigationBar() {
        navigationItem.title = pageTitle
        navigationItem.rightBarButtonItem = addButton
        let appearance = UINavigationBarAppearance()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.gray800, .font: LabelConfiguration.titleSemi18.font]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
}

extension RegisterItemListViewController {
    private func setSnapshot(items: [RegisterFormData]) {
        var snapshot = NSDiffableDataSourceSnapshot<SectionID, RegisterFormData>()
        items.forEach { item in
            let sectionID = UUID()
            snapshot.appendSections([sectionID])
            snapshot.appendItems([item], toSection: sectionID)
            
        }
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

extension RegisterItemListViewController {
    private func showErrorAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
