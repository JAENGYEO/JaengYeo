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
    
    let infoView = UIView().then {
        $0.backgroundColor = .gray50
    }
    let infoLabel = UILabel().then {
        $0.font = LabelConfiguration.body12.font
        $0.text = "AI가 부정확할 수 있으니 다시 한 번 확인해주세요"
        $0.textColor = .gray300
        $0.backgroundColor = .clear
        $0.textAlignment = .center
    }
    
    lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())
    
    private let bottomView = UIView().then {
        $0.backgroundColor = .gray50
    }
    
    let saveButton = UIButton().then {
        $0.setTitle("저장", for: .normal)
        $0.titleLabel?.font = LabelConfiguration.bodyMedium14.font
        $0.backgroundColor = .accent
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

extension RegisterItemListView {
    private func setLayout() {
        backgroundColor = .white
        collectionView.backgroundColor = .gray50
        infoView.addSubview(infoLabel)
        [infoView, collectionView, bottomView, saveButton].forEach { addSubview($0) }
        
        infoView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
        }
        
        infoLabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.top.bottom.equalToSuperview().inset(12)
        }
        
        collectionView.snp.makeConstraints {
            $0.top.equalTo(infoView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(bottomView.snp.top)
        }
        
        bottomView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.top.equalTo(saveButton.snp.top).offset(-8)
        }
        
        saveButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(safeAreaLayoutGuide).offset(-8)
            $0.height.equalTo(48)
        }
    }
}
