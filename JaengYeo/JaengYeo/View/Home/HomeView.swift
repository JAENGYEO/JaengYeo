//
//  HomeView.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/15/26.
//

import UIKit
import SnapKit
import Then

enum HomeSection: Int, CaseIterable {
    case unclassified
    case categorySummary
    case statusAlert
    case recentItems
    
    var title: String {
        switch self {
        case .unclassified:
            return ""
        case .categorySummary:
            return "전체 현황"
        case .statusAlert:
            return "상태 알림"
        case .recentItems:
            return "최근 등록"
        }
    }
}

enum HomeItem: Hashable {
    case unclassified(Int)
    case categorySummary(HomeViewModel.CategorySummary)
    case statusAlert(HomeViewModel.StatusSummary)
}

final class HomeView: UIView {
    
    lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout()).then {
        $0.backgroundColor = .white
        $0.showsVerticalScrollIndicator = false
        $0.register(UnclassifiedCell.self, forCellWithReuseIdentifier: UnclassifiedCell.id)
        $0.register(CategorySummaryCell.self, forCellWithReuseIdentifier: CategorySummaryCell.id)
        $0.register(StatusAlertCell.self, forCellWithReuseIdentifier: StatusAlertCell.id)
        $0.register(HomeSectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: HomeSectionHeaderView.id)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension HomeView {
    private func setLayout() {
        addSubview(collectionView)
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}

extension HomeView {
    private func createLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { sectionIndex, _ in
            let section = HomeSection(rawValue: sectionIndex)
            switch section {
            case .unclassified:
                return self.makeListUnclassifiedSection()
            case .categorySummary:
                return self.makeCategorySummarySection()
            case .statusAlert:
                return self.makeStatusAlertSection()
            case .recentItems:
                return self.makeListUnclassifiedSection()
            case .none:
                return self.makeListUnclassifiedSection()
            }
        }
    }
}

extension HomeView {
    private func makeListUnclassifiedSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(67))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(67))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 16, trailing: 16)
        section.interGroupSpacing = 8
        return section
    }
    
    private func makeCategorySummarySection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .absolute(133))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(133))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = .fixed(8)
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)
        
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(32))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        section.boundarySupplementaryItems = [header]
        return section
    }
    
    private func makeStatusAlertSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(66))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(66))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)
        section.interGroupSpacing = 8
        
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(32))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        section.boundarySupplementaryItems = [header]
        return section
    }
}
