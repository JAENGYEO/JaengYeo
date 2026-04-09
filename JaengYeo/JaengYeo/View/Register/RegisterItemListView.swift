//
//  RegisterItemListView.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/9/26.
//

import UIKit
import SnapKit
import Then

final class RegisterItemListView: UIView {
    
    let infoLabel = UILabel().then {
        $0.font = LabelConfiguration.body12.font
        $0.textColor = .secondaryLabel
        $0.textAlignment = .center
    }
    
    lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout()).then {
        $0.backgroundColor = .systemGroupedBackground
    }
    
    let saveButton = UIButton().then {
        $0.setTitle("저장", for: .normal)
        $0.backgroundColor = .systemBlue
        $0.layer.cornerRadius = 12
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

extension RegisterItemListView {
    private func configCollectionViewLayout() {
        var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        config.showsSeparators = true
        let layout = UICollectionViewCompositionalLayout.list(using: config)
        collectionView.setCollectionViewLayout(layout, animated: false)
    }
}

extension RegisterItemListView {
    private func setLayout() {
        backgroundColor = .white
        [infoLabel, collectionView, saveButton].forEach { addSubview($0) }
        
        infoLabel.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        collectionView.snp.makeConstraints {
            $0.top.equalTo(infoLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview()
        }
        
        saveButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(safeAreaLayoutGuide).offset(-16)
            $0.height.equalTo(48)
        }
    }
}
