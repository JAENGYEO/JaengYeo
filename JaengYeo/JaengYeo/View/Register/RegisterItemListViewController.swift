//
//  RegisterItemListViewController.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/10/26.
//

import UIKit
import RxSwift
import RxCocoa

protocol RegisterItemListViewControllerDelegate: AnyObject {
    func pushRegisterDetailView(item: RegisterFormData)
    func saveItems(items: [RegisterFormData])
}

final class RegisterItemListViewController: UIViewController {
    
    typealias SectionID = UUID
    
    weak var delegate: RegisterItemListViewControllerDelegate?
    
    private let disposeBag = DisposeBag()
    private let mainView = RegisterItemListView()
    
    private var items: [RegisterFormData]
    private let pageTitle: String
    
    private let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
    let addButtonTapped = PublishRelay<Void>()
    
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
        setSnapshot()
        mainView.collectionView.delegate = self
        bind()
    }
}

extension RegisterItemListViewController {
    private func bind() {
        mainView.saveButton.rx.tap
            .bind(onNext: { [weak self] in
                guard let self else { return }
                delegate?.saveItems(items: self.items)
            })
            .disposed(by: disposeBag)
        
        addButton.rx.tap
            .bind(to: addButtonTapped)
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
    private func setSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<SectionID, RegisterFormData>()
        items.forEach { item in
            let sectionID = UUID()
            snapshot.appendSections([sectionID])
            snapshot.appendItems([item], toSection: sectionID)
            
        }
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    func updateItem(item: RegisterFormData) {
        guard let index = items.firstIndex (where: { $0.id == item.id }) else { return }
        items[index] = item
        setSnapshot()
    }
    
    func appendItem(item: RegisterFormData) {
        items.append(item)
        setSnapshot()
    }
    
    func hasItem(id: UUID) -> Bool {
        items.contains(where: { $0.id == id })
    }
}

extension RegisterItemListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        delegate?.pushRegisterDetailView(item: item)
    }
}
