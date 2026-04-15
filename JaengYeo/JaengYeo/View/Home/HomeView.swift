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

final class HomeView: UIView {
    
    lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout()).then {
        $0.backgroundColor = .white
        $0.showsVerticalScrollIndicator = false
        $0.register(UnclassifiedCell.self, forCellWithReuseIdentifier: UnclassifiedCell.id)
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
            default:
                return self.makeListUnclassifiedSection()
            }
        }
    }
}

extension HomeView {
    private func makeListUnclassifiedSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(64))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(64))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 16, trailing: 16)
        section.interGroupSpacing = 8
        return section
    }
}
