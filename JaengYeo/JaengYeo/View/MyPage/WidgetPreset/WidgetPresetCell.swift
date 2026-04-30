//
//  WidgetPresetCell.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/30/26.
//

import UIKit
import SnapKit
import Then

final class WidgetPresetCell: UICollectionViewCell {
    static let id = "WidgetPresetCell"
    
    private let titleLabel = UILabel().then {
        $0.font = LabelConfiguration.titleSemi16.font
        $0.textColor = .gray800
        $0.numberOfLines = 1
    }
    private let countLabel = UILabel().then {
        $0.font = LabelConfiguration.body14.font
        $0.textColor = .gray500
        $0.numberOfLines = 1
    }
    private let chevronImageView = UIImageView().then {
        $0.image = .arrowIcon
        $0.tintColor = .gray300
        $0.contentMode = .scaleAspectFit
        $0.transform = CGAffineTransform(scaleX: -1, y: 1)
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
        countLabel.text = nil
    }
}

extension WidgetPresetCell {
    private func setLayout() {
        backgroundColor = .white
        [titleLabel, countLabel, chevronImageView].forEach { contentView.addSubview($0) }
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.trailing.lessThanOrEqualTo(countLabel.snp.leading).offset(-8)
        }
        countLabel.snp.makeConstraints {
            $0.trailing.equalTo(chevronImageView.snp.leading).offset(-8)
            $0.centerY.equalToSuperview()
        }
        chevronImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.size.equalTo(16)
        }
    }
}

extension WidgetPresetCell {
    func config(title: String, count: Int) {
        titleLabel.text = title
        countLabel.text = "상품 \(count) / 5"
    }
}
