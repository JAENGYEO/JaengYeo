//
//  ProductGroupListView.swift
//  JaengYeo
//
//  Created by Codex on 4/19/26.
//

import Then
import UIKit
import SnapKit
import RxCocoa
import RxSwift

final class ProductGroupListView: UIView {

    //MARK: - Enum
    private enum Section {
        case main
    }

    //MARK: - Properties
    private let disposeBag = DisposeBag()
    private let itemSelectedRelay = PublishRelay<ProductCellItem>()
    private lazy var dataSource = configureDataSource()

    //MARK: - Components
    /// 바텀 시트 시 뒷 배경
    let dimmingView = UIView().then {
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        $0.alpha = 0
    }

    /// 바텀 시트 컨텐츠 뷰
    let contentView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 20
        $0.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        $0.clipsToBounds = true
    }

    /// 상단 핸들 뷰
    private let handleView = UIView().then {
        $0.backgroundColor = .gray300
        $0.layer.cornerRadius = 2.5
    }

    /// 모달 타이틀
    let titleLabel = StyledLabel(config: .bodyMedium14).then {
        $0.textAlignment = .left
        $0.updateColor(.gray500)
    }

    /// 그룹 상품 컬렉션 뷰
    private lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: createLayout()
    ).then {
        $0.backgroundColor = .white
        $0.showsVerticalScrollIndicator = false
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
extension ProductGroupListView {
    /// 상품 셀 선택 이벤트
    var itemSelected: Observable<ProductCellItem> {
        itemSelectedRelay.asObservable()
    }

    /// 컬렉션 뷰 접근
    var productCollectionView: UICollectionView {
        collectionView
    }

    /// 스냅샷 적용
    func applySnapshot(with items: [ProductCellItem]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, ProductCellItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

//MARK: - DataSource
private extension ProductGroupListView {
    /// 데이터소스 설정
    private func configureDataSource() -> UICollectionViewDiffableDataSource<
        Section,
        ProductCellItem
    > {
        let cellRegistration = UICollectionView.CellRegistration<
            ProductCell,
            ProductCellItem
        > { [weak self]
            cell,
            indexPath,
            item in
            guard let self else { return }

            var freshness: Int? = nil
            if let expiryDate = item.product.expiryDate {
                freshness = self.makeFreshness(expiryDate)
            }

            let descriptions = [
                item.midCategory,
                item.subCategory,
            ].compactMap { $0 }
            
            var image: UIImage?
            if let url = item.product.imageUrl {
                image = ImageUtils.loadImage(fileName: url)
            } else {
                image = item.subCategoryImage
            }

            cell.updateUI(
                type: .homeType,
                title: item.displayTitle,
                freshness: freshness,
                descriptions: descriptions,
                subdescriptions: nil,
                count: item.totalQuantity,
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
    
    /// 소비기한 D-day 생성
    func makeFreshness(_ expiryDate: Date) -> Int? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let expiryDay = calendar.startOfDay(for: expiryDate)
        
        return calendar.dateComponents(
            [.day],
            from: today,
            to: expiryDay
        ).day
    }
}

//MARK: - Compositional Layout
private extension ProductGroupListView {
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
            top: 0,
            leading: 16,
            bottom: 16,
            trailing: 16
        )

        return UICollectionViewCompositionalLayout(section: section)
    }
}

//MARK: - Configure UI
private extension ProductGroupListView {
    /// UI 설정
    func configureUI() {
        overrideUserInterfaceStyle = .light
        backgroundColor = .clear

        addSubview(dimmingView)
        addSubview(contentView)

        contentView.addSubview(handleView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(collectionView)

        dimmingView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.top.greaterThanOrEqualToSuperview()
            $0.height.equalTo(280)
        }

        handleView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(40)
            $0.height.equalTo(5)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(handleView.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(20)
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }
}

//MARK: - Binding
private extension ProductGroupListView {
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

//MARK: - Date Format
private extension Date {
    /// 그룹 모달 날짜 표기
    var formattedGroupDate: String {
        ProductGroupListView.groupDateFormatter.string(from: self)
    }
}

private extension ProductGroupListView {
    /// 그룹 모달 날짜 포매터
    static let groupDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

#Preview {
    let viewController = UIViewController()
    let groupListView = ProductGroupListView()

    viewController.view.addSubview(groupListView)
    groupListView.snp.makeConstraints {
        $0.edges.equalToSuperview()
    }

    return viewController
}
