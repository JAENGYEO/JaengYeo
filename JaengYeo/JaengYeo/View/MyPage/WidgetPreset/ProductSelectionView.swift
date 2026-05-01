//
//  ProductSelectionView.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/30/26.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

enum ProductSelectionSection: Int, CaseIterable {
    case main
}

final class ProductSelectionView: UIView {

    let backButton = UIButton(type: .custom).then {
        let image = UIImage(named: "liquidArrowIcon")
        $0.setImage(image, for: .normal)
        $0.tintColor = .gray800
    }

    let searchBar = UISearchBar().then {
        $0.placeholder = "키워드 입력"
        $0.searchBarStyle = .minimal
        $0.returnKeyType = .search
        $0.backgroundImage = UIImage()
        $0.backgroundColor = .white
        $0.tintColor = .gray800

        let textField = $0.searchTextField
        textField.backgroundColor = .gray50
        textField.font = LabelConfiguration.body12.font
        textField.layer.cornerRadius = 20
        textField.layer.masksToBounds = true
        textField.borderStyle = .none
    }

    let counterLabel = UILabel().then {
        $0.font = LabelConfiguration.body12.font
        $0.textColor = .gray500
    }

    lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout()).then {
        $0.backgroundColor = .white
        $0.showsVerticalScrollIndicator = false
        $0.keyboardDismissMode = .onDrag
        $0.register(ProductCell.self, forCellWithReuseIdentifier: ProductCell.id)
    }

    let confirmButton = UIButton().then {
        $0.titleLabel?.font = LabelConfiguration.bodyMedium14.font
        $0.setTitle("완료", for: .normal)
        $0.setTitleColor(.white, for: .normal)
        $0.backgroundColor = .accent
        $0.layer.cornerRadius = 12
    }

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

extension ProductSelectionView {
    private func setLayout() {
        [backButton, searchBar, counterLabel, collectionView, confirmButton].forEach { addSubview($0) }

        backButton.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(12)
            $0.leading.equalToSuperview().offset(16)
            $0.size.equalTo(44)
        }

        searchBar.snp.makeConstraints {
            $0.centerY.equalTo(backButton)
            $0.leading.equalTo(backButton.snp.trailing).offset(8)
            $0.trailing.equalToSuperview().offset(-8)
        }

        counterLabel.snp.makeConstraints {
            $0.top.equalTo(backButton.snp.bottom).offset(12)
            $0.leading.equalToSuperview().offset(16)
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(counterLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(confirmButton.snp.top).offset(-8)
        }

        confirmButton.snp.makeConstraints {
            $0.bottom.equalTo(safeAreaLayoutGuide).offset(-8)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(48)
        }
    }
}

extension ProductSelectionView {
    private func configCollectionViewLayout() {
        let layout = UICollectionViewCompositionalLayout { _, environment in
            var config = UICollectionLayoutListConfiguration(appearance: .plain)
            config.showsSeparators = false
            config.backgroundColor = .clear
            let section = NSCollectionLayoutSection.list(using: config, layoutEnvironment: environment)
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)
            section.interGroupSpacing = 8
            return section
        }
        collectionView.setCollectionViewLayout(layout, animated: false)
    }
}
