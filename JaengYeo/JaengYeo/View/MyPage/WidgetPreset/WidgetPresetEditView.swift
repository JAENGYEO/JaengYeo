//
//  WidgetPresetEditView.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/30/26.
//

import UIKit
import SnapKit
import Then

enum WidgetPresetEditSection: Int, CaseIterable {
    case main
}

final class WidgetPresetEditView: UIView {
    let nameTextField = UITextField().then {
        $0.font = LabelConfiguration.body14.font
        $0.textColor = .gray800
        $0.placeholder = "프리셋 이름을 입력해주세요"
        $0.layer.borderColor = UIColor.gray200.cgColor
        $0.layer.borderWidth = 1
        $0.layer.cornerRadius = 8
        $0.setLeftPadding(12)
    }
    let countLabel = UILabel().then {
        $0.font = LabelConfiguration.body14.font
        $0.textColor = .gray500
    }
    lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout()).then {
        $0.backgroundColor = .white
        $0.showsVerticalScrollIndicator = false
        $0.register(SelectedProductCell.self, forCellWithReuseIdentifier: SelectedProductCell.id)
    }
    let addButton = UIButton().then {
        $0.titleLabel?.font = LabelConfiguration.titleSemi16.font
        $0.setTitle("+ 상품 추가", for: .normal)
        $0.setTitleColor(.accent, for: .normal)
        $0.setTitleColor(.gray400, for: .disabled)
        $0.layer.borderColor = UIColor.accent.cgColor
        $0.layer.borderWidth = 1
        $0.layer.cornerRadius = 12
    }
    let deleteButton = UIButton().then {
        $0.titleLabel?.font = LabelConfiguration.titleSemi16.font
        $0.setTitle("삭제하기", for: .normal)
        $0.setTitleColor(.primaryRed, for: .normal)
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

extension WidgetPresetEditView {
    private func setLayout() {
        [nameTextField, countLabel, collectionView, addButton, deleteButton].forEach { addSubview($0) }
        nameTextField.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(48)
        }
        countLabel.snp.makeConstraints {
            $0.top.equalTo(nameTextField.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        collectionView.snp.makeConstraints {
            $0.top.equalTo(countLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(addButton.snp.top).offset(-16)
        }
        addButton.snp.makeConstraints {
            $0.bottom.equalTo(deleteButton.snp.top).offset(-12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(48)
        }
        deleteButton.snp.makeConstraints {
            $0.bottom.equalTo(safeAreaLayoutGuide).inset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(48)
        }
    }
}

extension WidgetPresetEditView {
    private func createLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { _, _ in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(56))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(56))
            let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
            section.interGroupSpacing = 8
            return section
        }
    }
}

extension WidgetPresetEditView {
    func updateCountLabel(count: Int) {
        countLabel.text = "상품 \(count) / 5"
    }
    func updateDeleteButton(isVisible: Bool) {
        deleteButton.isHidden = !isVisible
    }
}
private extension UITextField {
    func setLeftPadding(_ width: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: width, height: frame.height))
        leftView = paddingView
        leftViewMode = .always
    }
}
