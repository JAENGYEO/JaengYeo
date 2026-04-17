//
//  UnclassifiedView.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/15/26.
//

import UIKit
import SnapKit
import Then

final class ItemListView: UIView {
    
    let infoView = UIView().then {
        $0.backgroundColor = .gray50
    }
    
    let infoLabel = UILabel().then {
        $0.font = LabelConfiguration.body12.font
        $0.textColor = .gray300
        $0.textAlignment = .center
    }
    
    lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout()).then {
        $0.backgroundColor = .gray50
        $0.showsVerticalScrollIndicator = false
        $0.register(ProductCell.self, forCellWithReuseIdentifier: ProductCell.id)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configCollectionViewLayout()
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ItemListView {
    private func setLayout() {
        backgroundColor = .white
        infoView.addSubview(infoLabel)
        [infoView, collectionView].forEach { addSubview($0) }
        
        infoView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
        }
        infoLabel.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(12)
            $0.leading.trailing.equalToSuperview()
        }
        collectionView.snp.makeConstraints {
            $0.top.equalTo(infoView.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }
}

extension ItemListView {
    private func configCollectionViewLayout() {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, environment in
            var config = UICollectionLayoutListConfiguration(appearance: .plain)
            config.showsSeparators = false
            config.backgroundColor = .clear
            let section = NSCollectionLayoutSection.list(using: config, layoutEnvironment: environment )
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16)
            section.interGroupSpacing = 8
            return section
        }
        collectionView.setCollectionViewLayout(layout, animated: false)
    }
}
