//
//  ProductCollectionView.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/9/26.
//

import SnapKit
import Then
import UIKit

final class ProductCollectionView: UIView {

    //MARK: - Properties
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
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 10,
                                                       weight: .medium)
        config.attributedTitle = title
        config.image = UIImage(systemName: "chevron.down",
                               withConfiguration: symbolConfig)
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
        $0.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }

    //MARK: - Co
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ProductCollectionView {

    func applySnapshot(with productDatas: [Product]) {
        totalCountLabel.text = "총 \(productDatas.count)개"
        var snapshot = NSDiffableDataSourceSnapshot<ProductCellType, Product>()
        snapshot.appendSections([.defaultType])
        snapshot.appendItems(productDatas, toSection: .defaultType)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    func configureDataSource() -> UICollectionViewDiffableDataSource<
        ProductCellType, Product
    > {
        let cellRegistration = UICollectionView.CellRegistration<
            ProductCell, Product
        > { cell, indexPath, item in
            cell.updateUI(
                type: .defaultType,
                title: item.name,
                freshness: nil,
                descriptions: [],
                subdescriptions: nil,
                count: Int(item.quantity)
            )
        }

        return UICollectionViewDiffableDataSource<ProductCellType, Product>(
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
        var listConfiguration = UICollectionLayoutListConfiguration(
            appearance: .plain
        )
        listConfiguration.showsSeparators = false
        listConfiguration.backgroundColor = .gray50

        return UICollectionViewCompositionalLayout.list(
            using: listConfiguration
        )
    }
}

extension ProductCollectionView {

    func configureUI() {
        backgroundColor = .gray50

        let infoView = UIView().then {
            $0.backgroundColor = .gray50
        }

        infoView.addSubview(totalCountLabel)
        infoView.addSubview(sortedButton)

        collectionView.register(
            ProductCell.self,
            forCellWithReuseIdentifier: "ProductCell"
        )

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

#Preview {
    ProductCollectionView()
}
