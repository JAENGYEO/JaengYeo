//
//  CategoryEditViewController.swift
//  JaengYeo
//
//  Created by Codex on 4/14/26.
//

import SnapKit
import Then
import UIKit

final class CategoryEditViewController: UIViewController {

    //MARK: - Enum
    private enum Section: CaseIterable {
        case midCategory
        case subCategory

        var title: String {
            switch self {
            case .midCategory:
                return "중분류"
            case .subCategory:
                return "소분류"
            }
        }
    }

    //MARK: - ViewModel
    private let viewModel: CategoryEditViewModel

    //MARK: - Properties
    private let coreDataManager: CoreDataManagerProtocol
    private lazy var dataSource = configureDataSource()

    //MARK: - Components
    private lazy var categoryCollectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: createLayout()
    ).then {
        $0.backgroundColor = .gray50
        $0.showsVerticalScrollIndicator = false
    }

    //MARK: - Init
    init(viewModel: CategoryEditViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureUI()
        applySnapshot()
    }
}

//MARK: - DataSource
private extension CategoryEditViewController {
    /// 데이터소스 설정
    private func configureDataSource() -> UICollectionViewDiffableDataSource<
        Section,
        CategoryEditItem
    > {
        let cellRegistration = UICollectionView.CellRegistration<
            CategorySelectionItemCell,
            CategoryEditItem
        > { cell, _, item in
            cell.updateUI(
                title: item.title,
                image: item.image,
                isSelect: false
            )
        }

        let headerRegistration = UICollectionView.SupplementaryRegistration<
            UICollectionViewListCell
        >(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { [weak self] headerView, _, indexPath in
            guard let section = self?.dataSource.sectionIdentifier(
                for: indexPath.section
            ) else { return }

            var contentConfiguration = UIListContentConfiguration.plainHeader()
            contentConfiguration.text = section.title
            contentConfiguration.textProperties.font = LabelConfiguration.bodyMedium14.font
            contentConfiguration.textProperties.color = .gray800
            headerView.contentConfiguration = contentConfiguration
            headerView.backgroundConfiguration = .clear()
        }

        let dataSource = UICollectionViewDiffableDataSource<
            Section,
            CategoryEditItem
        >(
            collectionView: categoryCollectionView
        ) { collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(
                using: cellRegistration,
                for: indexPath,
                item: item
            )
        }

        dataSource.supplementaryViewProvider = {
            collectionView,
            _,
            indexPath in
            collectionView.dequeueConfiguredReusableSupplementary(
                using: headerRegistration,
                for: indexPath
            )
        }

        return dataSource
    }

    /// 스냅샷 적용
    func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, CategoryEditItem>()
        snapshot.appendSections(Section.allCases)
 
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}


//MARK: - Compositional Layout
private extension CategoryEditViewController {
    /// 컬렉션 뷰 레이아웃 생성
    func createLayout() -> UICollectionViewLayout {
        let item = NSCollectionLayoutItem(
            layoutSize: .init(
                widthDimension: .fractionalWidth(0.2),
                heightDimension: .absolute(76)
            )
        )

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(76)
            ),
            repeatingSubitem: item,
            count: 5
        )

        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: .init(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(36)
            ),
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )

        let section = NSCollectionLayoutSection(group: group)
        section.boundarySupplementaryItems = [header]
        section.interGroupSpacing = 8
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 8,
            leading: 16,
            bottom: 24,
            trailing: 16
        )

        return UICollectionViewCompositionalLayout(section: section)
    }
}

//MARK: - Configure UI
private extension CategoryEditViewController {
    /// 네비게이션 바 설정
    func configureNavigationBar() {
        title = "분류 편집"
    }

    /// UI 설정
    func configureUI() {
        view.backgroundColor = .gray50

        view.addSubview(categoryCollectionView)

        categoryCollectionView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
}

#Preview {
    UINavigationController(
        rootViewController: CategoryEditViewController(
            viewModel: StockViewModel(coreDataManager: CoreDataManager())
        )
    )
}
