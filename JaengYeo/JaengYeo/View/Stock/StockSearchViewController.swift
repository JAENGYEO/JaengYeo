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

protocol StockSearchViewControllerDelegate: AnyObject {
    func stockSearchViewController(
        _ viewController: StockSearchViewController,
        didSelectProduct productID: UUID
    )
}

final class StockSearchViewController: BaseViewController {

    //MARK: - Input Limit
    private enum InputLimit {
        static let searchKeyword = 20
    }

    //MARK: - Enum
    private enum Section {
        case recentSearch
        case searchResult
    }

    private enum QuantityAction {
        case decrease(Product)
        case delete([UUID])
    }
    
    private enum SearchItem: Hashable {
        case recent(RecentSearchPayload)
        case product(ProductCellItem)
    }

    //MARK: - ViewModel
    private let viewModel: StockSearchViewModel

    //MARK: - Properties
    private let disposeBag = DisposeBag()
    private lazy var dataSource = configureDataSource()
    weak var delegate: StockSearchViewControllerDelegate?

    private let recentSearchDeletedRelay = PublishRelay<UUID>()
    private let deleteAllRecentSearchRelay = PublishRelay<Void>()
    private let productQuantityIncreasedRelay = PublishRelay<Product>()
    private let productQuantityDecreasedRelay = PublishRelay<Product>()
    private let productDeletedRelay = PublishRelay<[UUID]>()
    
    //MARK: - Components
    /// 뒤로가기 버튼
    private let backButton = UIButton(type: .custom).then {
        let image = UIImage(named: "liquidArrowIcon")
        $0.setImage(image, for: .normal)
        $0.tintColor = .white
    }

    /// 검색바
    private let searchBar = UISearchBar().then {
        $0.placeholder = "키워드 입력 (최대 20자)"
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
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        configureInputValidation()
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
    func configureInputValidation() {
        searchBar.delegate = self
    }

    func bind() {
        
        let searchText = searchBar.rx.text.orEmpty
            .debounce(.milliseconds(200), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .asObservable()
        
        let searchButtonTapped = searchBar.rx.searchButtonClicked
            .withLatestFrom(searchBar.rx.text.orEmpty)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .asObservable()
        
        let input = StockSearchViewModel.Input(
            viewDidLoad: Observable.just(()),
            searchText: searchText,
            searchButtonTapped: searchButtonTapped,
            deleteRecentSearch: recentSearchDeletedRelay.asObservable(),
            deleteAllRecentSearch: deleteAllRecentSearchRelay.asObservable(),
            productQuantityIncreased: productQuantityIncreasedRelay.asObservable(),
            productQuantityDecreased: productQuantityDecreasedRelay.asObservable(),
            productDeleted: productDeletedRelay.asObservable()
        )

        let output = viewModel.transform(input)

        Observable.combineLatest(searchText, output.recentSearches, output.products)
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] text, searches, products in
                let isEmpty = text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                self?.applySnapshot(
                    recentSearches: isEmpty ? searches : [],
                    products: isEmpty ? [] : products
                )
            })
            .disposed(by: disposeBag)

        backButton.rx.tap
            .bind(onNext: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)

        collectionView.rx.itemSelected
            .compactMap { [weak self] indexPath -> ProductCellItem? in
                guard
                    let self,
                    case let .product(item) = self.dataSource.itemIdentifier(
                        for: indexPath
                    )
                else { return nil }

                return item
            }
            .bind(onNext: { [weak self] item in
                self?.selectProduct(item)
            })
            .disposed(by: disposeBag)
    }
}

//MARK: - UISearchBarDelegate
extension StockSearchViewController: UISearchBarDelegate {
    func searchBar(
        _ searchBar: UISearchBar,
        shouldChangeTextIn range: NSRange,
        replacementText text: String
    ) -> Bool {
        let currentText = searchBar.text ?? ""
        let updatedText = (currentText as NSString).replacingCharacters(
            in: range,
            with: text
        )

        return updatedText.count <= InputLimit.searchKeyword
    }
}

//MARK: - DataSource
private extension StockSearchViewController {
    
    /// 스냅샷
    func applySnapshot(recentSearches: [RecentSearchPayload], products: [ProductCellItem]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, SearchItem>()
        
        if !recentSearches.isEmpty {
            snapshot.appendSections([.recentSearch])
            snapshot.appendItems(
                recentSearches.map { .recent($0) },
                toSection: .recentSearch
            )
        }
        
        if !products.isEmpty {
            snapshot.appendSections([.searchResult])
            snapshot.appendItems(
                products.map { .product($0) },
                toSection: .searchResult
            )
        }
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    /// 데이터소스 설정
    private func configureDataSource() -> UICollectionViewDiffableDataSource<
        Section,
        SearchItem
    > {
        let searchRegistration = UICollectionView.CellRegistration<RecentSearchCell, RecentSearchPayload> { [weak self] cell, _, item in
            cell.config(keyword: item.keyword)
            cell.deleteButton.rx.tap
                .map { item.id }
                .bind(to: self?.recentSearchDeletedRelay ?? PublishRelay<UUID>())
                .disposed(by: cell.disposeBag)
        }
        
        
        let productRegistration = UICollectionView.CellRegistration<
            ProductCell,
            ProductCellItem
        > { [weak self] cell, _, item in
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

            cell.bindAddButtonTap { [weak self] in
                self?.productQuantityIncreasedRelay.accept(item.product)
            }

            cell.bindDeleteButtonTap { [weak self] in
                guard let self else { return }

                self.makeDecreaseAction(item: item)
                    .bind(onNext: { action in
                        switch action {
                        case .decrease(let product):
                            self.productQuantityDecreasedRelay.accept(product)
                        case .delete(let productIDs):
                            self.productDeletedRelay.accept(productIDs)
                        }
                    })
                    .disposed(by: self.disposeBag)
            }
        }

        let headerRegistration = UICollectionView.SupplementaryRegistration<RecentSearchHeaderView>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { [weak self] headerView, _, _ in
            headerView.deleteAllButton.rx.tap
                .bind(to: self?.deleteAllRecentSearchRelay ?? PublishRelay<Void>())
                .disposed(by: headerView.disposeBag)
        }

        let dataSource = UICollectionViewDiffableDataSource<Section, SearchItem>(
            collectionView: collectionView
        ) { collectionView, indexPath, item in
            switch item {
            case .recent(let payload):
                return collectionView.dequeueConfiguredReusableCell(
                    using: searchRegistration,
                    for: indexPath,
                    item: payload
                )
            case .product(let product):
                return collectionView.dequeueConfiguredReusableCell(
                    using: productRegistration,
                    for: indexPath,
                    item: product
                )
            }
        }

        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            collectionView.dequeueConfiguredReusableSupplementary(
                using: headerRegistration,
                for: indexPath
            )
        }

        return dataSource
    }
}

//MARK: - Action
private extension StockSearchViewController {
    /// 상품 선택
    func selectProduct(_ item: ProductCellItem) {
        delegate?.stockSearchViewController(
            self,
            didSelectProduct: item.product.id
        )
    }

    /// 상품 재고 차감 액션 생성
    private func makeDecreaseAction(
        item: ProductCellItem
    ) -> Observable<QuantityAction> {
        guard item.product.quantity == 1 else {
            return .just(.decrease(item.product))
        }

        return AlertController.rx.alert(
            on: self,
            image: UIImage(named: "alertBlue") ?? UIImage(),
            title: "재고가 0개 입니다.",
            message: "확인을 누르시면 해당 물품이 삭제됩니다.",
            actions: [
                .cancel("취소"),
                .default("확인")
            ]
        )
        .filter { $0.title == "확인" }
        .map { _ in .delete([item.product.id]) }
        .asObservable()
    }
}

//MARK: - Compositional Layout
private extension StockSearchViewController {
    /// 컬렉션 뷰 레이아웃 생성
    
    func createLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ in
            guard let self,
                  let section = self.dataSource.sectionIdentifier(for: sectionIndex) else { return nil }
            switch section {
            case .recentSearch:
                return self.createRecentSearchSection()
            case .searchResult:
                return self.createSearchResultSection()
            }
        }
    }
    
    func createRecentSearchSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: .init(
                widthDimension: .estimated(100),
                heightDimension: .absolute(34)
            )
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(
                widthDimension: .estimated(100),
                heightDimension: .absolute(34)),
            subitems: [item]
        )
        
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(20)
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )

        let section = NSCollectionLayoutSection(group: group)
        section.boundarySupplementaryItems = [header]
        section.interGroupSpacing = 8
        section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        section.orthogonalScrollingBehavior = .continuous
        return section
    }
    
    func createSearchResultSection() -> NSCollectionLayoutSection {
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

        return section
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
