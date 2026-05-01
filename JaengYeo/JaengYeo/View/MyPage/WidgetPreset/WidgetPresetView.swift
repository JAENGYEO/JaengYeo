//
//  WidgetPresetView.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/30/26.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

enum WidgetPresetSection: Int, CaseIterable {
    case main
}

final class WidgetPresetView: UIView {
    lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout()).then {
        $0.backgroundColor = .white
        $0.showsVerticalScrollIndicator = false
        $0.register(WidgetPresetCell.self, forCellWithReuseIdentifier: WidgetPresetCell.id)
    }
    
    let emptyPresetView = EmptyStateView().then {
        $0.isHidden = true
    }
    
    let swipeDeleteRelay = PublishRelay<IndexPath>()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        configCollectionViewLayout()
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
    private func configCollectionViewLayout() {
        let layout = UICollectionViewCompositionalLayout { _, environment in
            var config = UICollectionLayoutListConfiguration(appearance: .plain)
            config.showsSeparators = false
            config.backgroundColor = .clear
            config.trailingSwipeActionsConfigurationProvider = { [weak self] indexPath in
                let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] _, _, completion in
                    self?.swipeDeleteRelay.accept(indexPath)
                    completion(true)
                }
                deleteAction.image = UIImage(systemName: "trash")
                return UISwipeActionsConfiguration(actions: [deleteAction])
            }
            let section = NSCollectionLayoutSection.list(using: config, layoutEnvironment: environment)
            section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 16, trailing: 16)
            section.interGroupSpacing = 8
            return section
        }
        collectionView.setCollectionViewLayout(layout, animated: false)
    }
}
