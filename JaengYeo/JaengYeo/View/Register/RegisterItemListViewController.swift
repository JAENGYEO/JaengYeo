//
//  RegisterItemListViewController.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/10/26.
//

import UIKit
import RxSwift
import RxCocoa

final class RegisterItemListViewController: BaseViewController {
    
    private let disposeBag = DisposeBag()
    private let mainView = RegisterItemListView()
    private let viewModel: RegisterItemListViewModel
    private let pageTitle: String
    private let infoLabel: String
    
    private let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    init(viewModel: RegisterItemListViewModel, pageTitle: String, infoLabel: String) {
        self.viewModel = viewModel
        self.pageTitle = pageTitle
        self.infoLabel = infoLabel
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var dataSource: UICollectionViewDiffableDataSource<Int, RegisterFormData> = {
        return UICollectionViewDiffableDataSource<Int, RegisterFormData>(collectionView: mainView.collectionView) { collectionView, indexPath, itemIdentifier in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProductCell.id, for: indexPath) as? ProductCell else { return UICollectionViewCell() }
            
            var descriptions: [String] = []
            if let midCategory = itemIdentifier.midCategoryName { descriptions.append(midCategory) }
            if let subCategory = itemIdentifier.subCategoryName { descriptions.append(subCategory) }
            if let quantity = itemIdentifier.quantity { descriptions.append("\(quantity)개") }
            
            if let expiryDate = itemIdentifier.expiryDate {
                let today = Calendar.current.startOfDay(for: Date())
                let expiry = Calendar.current.startOfDay(for: expiryDate)
                let dateString: String
                if today == expiry {
                    dateString = "오늘까지"
                } else {
                    dateString = self.dateFormatter.string(from: expiryDate) + "까지"
                }
                cell.updateUI(
                    type: .registType,
                    title: itemIdentifier.name ?? "정보 없음",
                    freshness: nil,
                    descriptions: [dateString],
                    subdescriptions: descriptions,
                    count: nil,
                    image: itemIdentifier.image ?? itemIdentifier.subCategoryIconName.flatMap { UIImage(named: $0) }
                    
                )
            } else {
                cell.updateUI(
                    type: .registType,
                    title: itemIdentifier.name ?? "정보 없음",
                    freshness: nil,
                    descriptions: descriptions,
                    subdescriptions: nil,
                    count: nil,
                    image: itemIdentifier.image ?? itemIdentifier.subCategoryIconName.flatMap { UIImage(named: $0) }
                )
            }
            cell.accessories = [.disclosureIndicator(options: .init(tintColor: .gray300))]
            return cell
        }
    }()
    
    override func loadView() {
        self.view = mainView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mainView.collectionView.register(ProductCell.self, forCellWithReuseIdentifier: ProductCell.id)
        configNavigationBar()
        bind()
        mainView.infoLabel.text = infoLabel
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
        
        let cellDeleted = mainView.swipeDeleteRelay
            .flatMapLatest { [weak self] indexPath -> Observable<UUID> in
                guard let self,
                      let id = self.dataSource.itemIdentifier(for: indexPath)?.id else { return .empty() }
                return self.showDeleteAlert(id: id)
            }
            .asObservable()
        
        let input = RegisterItemListViewModel.Input(
            saveButtonTapped: mainView.saveButton.rx.tap.asObservable(),
            addButtonTapped: addButton.rx.tap.asObservable(),
            cellTapped: cellTapped,
            cellDeleted: cellDeleted
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
        
        output.isSaveEnabled
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] isEnabled in
                self?.mainView.saveButton.isEnabled = isEnabled
                self?.mainView.saveButton.backgroundColor = isEnabled ? .accent: .accent.withAlphaComponent(0.3)
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
        let currentItemIds = Set(dataSource.snapshot().itemIdentifiers.map { $0.id })
        
        var snapshot = NSDiffableDataSourceSnapshot<Int, RegisterFormData>()
        snapshot.appendSections([0])
        snapshot.appendItems(items, toSection: 0)
        let itemsToReconfig = items.filter { currentItemIds.contains($0.id) }
        if !itemsToReconfig.isEmpty {
            snapshot.reconfigureItems(itemsToReconfig)
        }
        
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

extension RegisterItemListViewController {
    private func showErrorAlert(title: String, message: String) {
        let alert = AlertController(
            image: .warningIcon,
            title: title,
            message: message,
            actions: [.default("확인")]
        )
        present(alert, animated: true)
    }
}

extension RegisterItemListViewController {
    private func showDeleteAlert(id: UUID) -> Observable<UUID> {
        return Reactive<AlertController>.alert(
            on: self,
            image: UIImage(systemName: "trash.fill")!,
            title: "삭제",
            message: "해당 항목을 삭제하시겠습니까?",
            actions: [
                .cancel("취소"),
                .destructive("삭제")
            ]
        )
        .filter { $0.style == .destructive }
        .map { _ in id }
        .asObservable()
    }
}
