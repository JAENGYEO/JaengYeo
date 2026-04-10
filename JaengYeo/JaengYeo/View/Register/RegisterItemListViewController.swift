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
    
    private var items: [RegisterFormData]
    private let pageTitle: String
    
    init(items: [RegisterFormData], pageTitle: String) {
        self.items = items
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
        loadMockData()
    }
}

extension RegisterItemListViewController {
    private func loadMockData() {
        items = [
            RegisterFormData(name: "김밥", mainCategory: "김밥", quantity: 10),
            RegisterFormData(name: "라면", mainCategory: "라면", quantity: 5),
            RegisterFormData(name: "초밥", mainCategory: "초밥", quantity: 3),
            RegisterFormData(name: "짬뽕", mainCategory: "짬뽕", quantity: 8),
            RegisterFormData(name: "파스타", mainCategory: "파스타", quantity: 4),
            RegisterFormData(name: "삼겹살", mainCategory: "삼겹살", quantity: 6),
            RegisterFormData(name: "피자", mainCategory: "피자", quantity: 2),
            RegisterFormData(name: "치킨", mainCategory: "치킨", quantity: 9)
        ]
        setSnapshot()
    }
}

extension RegisterItemListViewController {
    private func configNavigationBar() {
        navigationItem.title = pageTitle
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
        let appearance = UINavigationBarAppearance()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.gray800]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
}

extension RegisterItemListViewController {
    private func setSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<SectionID, RegisterFormData>()
        items.forEach { item in
            let sectionID = UUID()
            snapshot.appendSections([sectionID])
            snapshot.appendItems([item], toSection: sectionID)
            
        }
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}
