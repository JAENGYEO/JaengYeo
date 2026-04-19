//
//  ProductCollectionView.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/9/26.
//

import Then
import UIKit
import SnapKit
import RxCocoa
import RxSwift

final class ProductCollectionView: UIView {

    //MARK: - Properties
    private let disposeBag = DisposeBag()
    private let itemSelectedRelay = PublishRelay<ProductCellItem>()
    private let swipeDecreaseRelay = PublishRelay<IndexPath>()
    private let swipeDeleteRelay = PublishRelay<IndexPath>()
    private let itemQuantityDecreasedRelay = PublishRelay<ProductCellItem>()
    private let itemDeletedRelay = PublishRelay<ProductCellItem>()
    private lazy var dataSource = configureDataSource()

    //MARK: - Components
    private let totalCountLabel = StyledLabel(
        config: LabelConfiguration.body12.updatingColor(color: .gray500)
    ).then {
        $0.text = "총 0개"
    }

    private let sortedButton = UIButton(configuration: .plain()).then {
        var config = UIButton.Configuration.plain()

        var title = AttributedString("최근 등록순")
        title.font = .systemFont(ofSize: 12, weight: .regular)
        title.foregroundColor = .gray800
        let symbolConfig = UIImage.SymbolConfiguration(
            pointSize: 10,
            weight: .medium
        )
        config.attributedTitle = title
        config.image = UIImage(
            systemName: "chevron.down",
            withConfiguration: symbolConfig
        )
        config.baseForegroundColor = .gray800
        config.imagePlacement = .trailing
        config.imagePadding = 1
        config.contentInsets = .zero

        $0.configuration = config
    }

    private lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: createLayout()
    ).then {
        $0.backgroundColor = .gray50
    }

    //MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
        bind()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//MARK: - Public
extension ProductCollectionView {
    /// 정렬 메뉴 설정
    func configureSortMenu(
        onSelect: @escaping (ProductSortOption) -> Void
    ) {
        sortedButton.showsMenuAsPrimaryAction = true
        sortedButton.menu = UIMenu(
            children: ProductSortOption.allCases.map { option in
                UIAction(title: option.rawValue) { _ in
                    onSelect(option)
                }
            }
        )
    }

    /// 정렬 타이틀 변경
    func updateSortTitle(_ title: String) {
        var config = sortedButton.configuration ?? .plain()

        var attributedTitle = AttributedString(title)
        attributedTitle.font = .systemFont(ofSize: 12, weight: .regular)
        attributedTitle.foregroundColor = .gray800
        config.attributedTitle = attributedTitle

        sortedButton.configuration = config
    }
    
    /// 상품 셀 선택 이벤트
    var itemSelected: Observable<ProductCellItem> {
        itemSelectedRelay.asObservable()
    }
    
    /// 상품 재고 차감 이벤트
    var itemQuantityDecreased: Observable<ProductCellItem> {
        itemQuantityDecreasedRelay.asObservable()
    }
    
    /// 상품 셀 삭제 이벤트
    var itemDeleted: Observable<ProductCellItem> {
        itemDeletedRelay.asObservable()
    }

    /// 스냅샷 적용
    func applySnapshot(with productDatas: [ProductCellItem]) {
        let totalCount = productDatas.reduce(0) {
            $0 + $1.groupedCount
        }
        totalCountLabel.text = "총 \(totalCount)개"
        var snapshot = NSDiffableDataSourceSnapshot<
            ProductCellType, ProductCellItem
        >()
        snapshot.appendSections([.defaultType])
        snapshot.appendItems(productDatas, toSection: .defaultType)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

//MARK: - DataSource
private extension ProductCollectionView {
    /// 데이터소스 설정
    func configureDataSource() -> UICollectionViewDiffableDataSource<
        ProductCellType, ProductCellItem
    > {
        let cellRegistration = UICollectionView.CellRegistration<
            ProductCell, ProductCellItem
        > { [weak self]
            cell,
            indexPath,
            item in

            var freshness: Int? = nil
            if let expiryDate = item.product.expiryDate {
                freshness = self?.makeFreshness(expiryDate)
            }

            let descriptions = [
                item.midCategory,
                item.subCategory,
            ].compactMap { $0 }

            cell.updateUI(
                type: .defaultType,
                title: item.displayTitle,
                freshness: freshness,
                descriptions: descriptions,
                subdescriptions: nil,
                count: item.totalQuantity,
                image: nil
            )
        }

        return UICollectionViewDiffableDataSource<
            ProductCellType, ProductCellItem
        >(
            collectionView: collectionView
        ) { collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(
                using: cellRegistration,
                for: indexPath,
                item: item
            )
        }
    }
    
    /// 소비기한 D-day 생성
    func makeFreshness(_ expiryDate: Date) -> Int? {
        let day = Calendar.current.dateComponents(
            [.day],
            from: Date(),
            to: expiryDate
        ).day
        
        return day.map { $0 + 1 }
    }
}

//MARK: - Compositional Layout
private extension ProductCollectionView {
    /// 컬렉션 뷰 레이아웃 생성
    func createLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { _, environment in
            var configuration = UICollectionLayoutListConfiguration(
                appearance: .plain
            )
            configuration.showsSeparators = false
            configuration.backgroundColor = .clear
            configuration.trailingSwipeActionsConfigurationProvider = {
                [weak self] indexPath in
                let deleteAction = UIContextualAction(
                    style: .destructive,
                    title: nil
                ) { [weak self] _, _, completion in
                    self?.swipeDeleteRelay.accept(indexPath)
                    completion(true)
                }
                deleteAction.image = UIImage(systemName: "trash")
                
                let actions = self?.makeSwipeActions(
                    indexPath: indexPath,
                    deleteAction: deleteAction
                ) ?? [deleteAction]
                
                let configuration = UISwipeActionsConfiguration(actions: actions)
                configuration.performsFirstActionWithFullSwipe = false
                return configuration
            }

            let section = NSCollectionLayoutSection.list(
                using: configuration,
                layoutEnvironment: environment
            )
            section.contentInsets = NSDirectionalEdgeInsets(
                top: 0,
                leading: 16,
                bottom: 0,
                trailing: 16
            )
            section.interGroupSpacing = 8
            return section
        }
    }
}

//MARK: - Configure UI
private extension ProductCollectionView {
    /// UI 설정
    func configureUI() {
        backgroundColor = .gray50

        let infoView = UIView().then {
            $0.backgroundColor = .gray50
        }

        infoView.addSubview(totalCountLabel)
        infoView.addSubview(sortedButton)

        addSubview(infoView)
        addSubview(collectionView)

        infoView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(40)
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(infoView.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        totalCountLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalToSuperview().offset(16)
        }

        sortedButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview().inset(16)
        }
    }
}

//MARK: - Action State
private extension ProductCollectionView {
    /// 스와이프 액션 목록 생성
    func makeSwipeActions(
        indexPath: IndexPath,
        deleteAction: UIContextualAction
    ) -> [UIContextualAction] {
        guard canDecreaseQuantity(at: indexPath) else {
            return [deleteAction]
        }
        
        let decreaseAction = UIContextualAction(
            style: .normal,
            title: ""
        ) { [weak self] _, _, completion in
            self?.swipeDecreaseRelay.accept(indexPath)
            completion(false)
        }
        decreaseAction.image = UIImage(systemName: "minus")
        decreaseAction.backgroundColor = .accent
        
        return [deleteAction, decreaseAction]
    }
    
    /// 재고 차감 가능 여부
    func canDecreaseQuantity(at indexPath: IndexPath) -> Bool {
        guard let item = dataSource.itemIdentifier(for: indexPath) else {
            return false
        }
        
        return item.product.quantity > 0
    }
}

//MARK: - Binding
private extension ProductCollectionView {
    func bind() {
        collectionView.rx.itemSelected
            .do(onNext: { [weak self] indexPath in
                self?.collectionView.deselectItem(
                    at: indexPath,
                    animated: false
                )
            })
            .compactMap { [weak self] indexPath in
                self?.dataSource.itemIdentifier(for: indexPath)
            }
            .bind(to: itemSelectedRelay)
            .disposed(by: disposeBag)
        
        swipeDecreaseRelay
            .compactMap { [weak self] indexPath in
                self?.dataSource.itemIdentifier(for: indexPath)
            }
            .bind(to: itemQuantityDecreasedRelay)
            .disposed(by: disposeBag)
        
        swipeDeleteRelay
            .compactMap { [weak self] indexPath in
                self?.dataSource.itemIdentifier(for: indexPath)
            }
            .bind(to: itemDeletedRelay)
            .disposed(by: disposeBag)
    }
}
