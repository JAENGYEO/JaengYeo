//
//  ProductCollectionView.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/9/26.
//

import SnapKit
import Then
import UIKit
import RxCocoa
import RxSwift

final class ProductCollectionView: UIView {

    //MARK: - Properties
    private let disposeBag = DisposeBag()
    private let itemSelectedRelay = PublishRelay<ProductCellItem>()
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

//MARK: - Configure CollectionView
extension ProductCollectionView {
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

    func configureDataSource() -> UICollectionViewDiffableDataSource<
        ProductCellType, ProductCellItem
    > {
        let cellRegistration = UICollectionView.CellRegistration<
            ProductCell, ProductCellItem
        > {
            cell,
            indexPath,
            item in

            var freshness: Int? = nil
            if let expiryDate = item.product.expiryDate {
                freshness =
                    Calendar.current.dateComponents(
                        [.day],
                        from: Date(),
                        to: expiryDate
                    ).day
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
            top: 0,
            leading: 16,
            bottom: 0,
            trailing: 16
        )

        return UICollectionViewCompositionalLayout(section: section)
    }
}

// MARK: - Configure UI
extension ProductCollectionView {
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
    }
}
