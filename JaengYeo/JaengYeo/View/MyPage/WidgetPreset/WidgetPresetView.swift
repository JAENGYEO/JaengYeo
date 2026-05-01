//
//  WidgetPresetView.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/30/26.
//

import UIKit
import SnapKit
import Then

enum WidgetPresetSection: Int, CaseIterable {
    case main
}

final class WidgetPresetView: UIView {
    lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout()).then {
        $0.backgroundColor = .white
        $0.showsVerticalScrollIndicator = false
        $0.register(WidgetPresetCell.self, forCellWithReuseIdentifier: WidgetPresetCell.id)
    }
    
    let emptyPresetView = EmptyStateView().then {
        $0.isHidden = true
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

extension WidgetPresetView {
    private func setLayout() {
        [collectionView, emptyPresetView].forEach { addSubview($0) }
        
        collectionView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        
        emptyPresetView.snp.makeConstraints {
            $0.edges.equalTo(safeAreaLayoutGuide)
        }
    }
}

extension WidgetPresetView {
    private func createLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { _, _ in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(56))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(56))
            let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 16, trailing: 16)
            section.interGroupSpacing = 8
            return section
        }
    }
}
