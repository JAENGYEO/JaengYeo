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
    }

    //MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//MARK: - Configure CollectionView
extension ProductCollectionView {
    func applySnapshot(with productDatas: [ProductCellItem]) {
        totalCountLabel.text = "총 \(productDatas.count)개"
        var snapshot = NSDiffableDataSourceSnapshot<ProductCellType, ProductCellItem>()
        snapshot.appendSections([.defaultType])
        snapshot.appendItems(productDatas, toSection: .defaultType)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    func configureDataSource() -> UICollectionViewDiffableDataSource<ProductCellType, ProductCellItem> {
        let cellRegistration = UICollectionView.CellRegistration<ProductCell, ProductCellItem> {
            cell, indexPath, item in
            
            var freshness: Int? = nil
            if let expiryDate = item.product.expiryDate {
                freshness = Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day
            }
            
            let descriptions = [
                item.midCategory,
                item.subCategory
            ].compactMap { $0 }
            
            cell.updateUI(
                type: .defaultType,
                title: item.product.name,
                freshness: freshness,
                descriptions: descriptions,
                subdescriptions: nil,
                count: item.product.quantity,
                image: nil
            )
        }

        return UICollectionViewDiffableDataSource<ProductCellType, ProductCellItem>(
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
