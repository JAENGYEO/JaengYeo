//
//  ProductSelectionCell.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/30/26.
//

import UIKit
import SnapKit
import Then

final class ProductSelectionCell: UICollectionViewCell {
    static let id = "ProductSelectionCell"
    
    private let titleLabel = UILabel().then {
        $0.font = LabelConfiguration.titleSemi16.font
        $0.textColor = .gray800
        $0.numberOfLines = 1
    }
    private let categoryLabel = UILabel().then {
        $0.font = LabelConfiguration.body14.font
        $0.textColor = .gray500
        $0.numberOfLines = 1
    }
    private let checkmarkImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        categoryLabel.text = nil
        checkmarkImageView.image = nil
        contentView.alpha = 1
        isUserInteractionEnabled = true
    }
}

extension ProductSelectionCell {
    private func setLayout() {
        backgroundColor = .white
        [titleLabel, categoryLabel, checkmarkImageView].forEach { contentView.addSubview($0) }
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.top.equalToSuperview().offset(8)
            $0.trailing.lessThanOrEqualTo(checkmarkImageView.snp.leading).offset(-8)
        }
        categoryLabel.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.top.equalTo(titleLabel.snp.bottom).offset(2)
            $0.trailing.lessThanOrEqualTo(checkmarkImageView.snp.leading).offset(-8)
        }
        checkmarkImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.size.equalTo(20)
        }
    }
}

extension ProductSelectionCell {
    func config(title: String, category: String, isSelected: Bool, isEnabled: Bool) {
        titleLabel.text = title
        categoryLabel.text = category
        checkmarkImageView.image = isSelected ? UIImage(systemName: "checkmark.circle.fill") : UIImage(systemName: "circle")
        checkmarkImageView.tintColor = isSelected ? .accent : .gray300
        contentView.alpha = isEnabled ? 1 : 0.4
        isUserInteractionEnabled = isEnabled
    }
}
