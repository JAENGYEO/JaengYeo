//
//  StockSearchViewController.swift
//  JaengYeo
//
//  Created by Codex on 4/15/26.
//

import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

final class StockSearchViewController: BaseViewController {

    //MARK: - Enum
    private enum Section {
        case main
    }

    //MARK: - ViewModel
    private let viewModel: StockSearchViewModel

    //MARK: - Properties
    private let disposeBag = DisposeBag()
    private lazy var dataSource = configureDataSource()

    //MARK: - Components
    /// 뒤로가기 버튼
    private let backButton = UIButton(type: .custom).then {
        let image = UIImage(named: "liquidArrowIcon")
        $0.setImage(image, for: .normal)
        $0.tintColor = .white
    }

    /// 검색바
    private let searchBar = UISearchBar().then {
        $0.placeholder = "키워드 입력"
        $0.searchBarStyle = .minimal
        $0.returnKeyType = .search
        $0.backgroundImage = UIImage()
        $0.barTintColor = .clear
        $0.backgroundColor = .white
        $0.tintColor = .gray800
        
        let textField = $0.searchTextField
        textField.backgroundColor = .gray50
        textField.font = LabelConfiguration.bodyMedium14.font
        textField.layer.cornerRadius = 20
        textField.layer.masksToBounds = true
        textField.borderStyle = .none
    }

    /// 검색 결과 컬렉션 뷰
    private lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: createLayout()
    ).then {
        $0.backgroundColor = .white
        $0.keyboardDismissMode = .onDrag
    }

    //MARK: - Init
    init(viewModel: StockSearchViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        overrideUserInterfaceStyle = .light
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchBar.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
}

//MARK: - Binding
private extension StockSearchViewController {
    func bind() {
        let input = StockSearchViewModel.Input(
            viewDidLoad: Observable.just(()),
            searchText: searchBar.rx.text.orEmpty
                .debounce(.milliseconds(200), scheduler: MainScheduler.instance)
                .distinctUntilChanged()
                .asObservable()
        )

        let output = viewModel.transform(input)

        output.products
            .bind(onNext: { [weak self] products in
                self?.applySnapshot(with: products)
            })
            .disposed(by: disposeBag)

        backButton.rx.tap
            .bind(onNext: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
    }
}

//MARK: - DataSource
private extension StockSearchViewController {
    
    /// 스냅샷
    func applySnapshot(with products: [ProductCellItem]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, ProductCellItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(products, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    /// 데이터소스 설정
    private func configureDataSource() -> UICollectionViewDiffableDataSource<
        Section,
        ProductCellItem
    > {
        let cellRegistration = UICollectionView.CellRegistration<
            ProductCell,
            ProductCellItem
        > { cell, _, item in
            var freshness: Int? = nil
            if let expiryDate = item.product.expiryDate {
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let expiryDay = calendar.startOfDay(for: expiryDate)
                
                freshness = calendar.dateComponents(
                    [.day],
                    from: today,
                    to: expiryDay
                ).day
            }

            let descriptions = [
                item.midCategory,
                item.subCategory
            ].compactMap { $0 }
            
            var image: UIImage?
            if let url = item.product.imageUrl {
                image = ImageUtils.loadImage(fileName: url)
            } else {
                image = item.subCategoryImage
            }

            cell.updateUI(
                type: .homeType,
                title: item.product.name,
                freshness: freshness,
                descriptions: descriptions,
                subdescriptions: nil,
                count: item.product.quantity,
                image: image
            )
        }

        return UICollectionViewDiffableDataSource<Section, ProductCellItem>(
            collectionView: collectionView
        ) { collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(
                using: cellRegistration,
                for: indexPath,
                item: item
            )
        }
    }
}

//MARK: - Compositional Layout
private extension StockSearchViewController {
    /// 컬렉션 뷰 레이아웃 생성
    func createLayout() -> UICollectionViewLayout {
        let item = NSCollectionLayoutItem(
            layoutSize: .init(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(88)
            )
        )

        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: .init(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(88)
            ),
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 8
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 8,
            leading: 16,
            bottom: 0,
            trailing: 16
        )

        return UICollectionViewCompositionalLayout(section: section)
    }
}

//MARK: - Configure UI
private extension StockSearchViewController {
    /// UI 설정
    func configureUI() {
        view.backgroundColor = .white

        view.addSubview(backButton)
        view.addSubview(searchBar)
        view.addSubview(collectionView)

        backButton.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(0)
            $0.leading.equalToSuperview().offset(16)
            $0.size.equalTo(54)
        }

        searchBar.snp.makeConstraints {
            $0.centerY.equalTo(backButton.snp.centerY)
            $0.leading.equalTo(backButton.snp.trailing).offset(8)
            $0.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(40)
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom).offset(12)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }
}

#Preview {
    StockSearchViewController(
        viewModel: StockSearchViewModel(coreDataManager: CoreDataManager())
    )
}
