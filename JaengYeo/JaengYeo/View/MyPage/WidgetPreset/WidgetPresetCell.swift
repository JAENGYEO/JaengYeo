//
//  WidgetPresetCell.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/30/26.
//

import UIKit
import SnapKit
import Then

final class WidgetPresetCell: UICollectionViewListCell {
    static let id = "WidgetPresetCell"
    
    private let titleLabel = UILabel().then {
        $0.font = LabelConfiguration.bodyMedium14.font
        $0.textColor = .gray800
        $0.numberOfLines = 1
    }
    private let countLabel = UILabel().then {
        $0.font = LabelConfiguration.body12.font
        $0.textColor = .gray300
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
        [titleLabel, countLabel, chevronImageView].forEach { contentView.addSubview($0) }
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.top.bottom.equalToSuperview().inset(16)
            $0.trailing.lessThanOrEqualTo(countLabel.snp.leading).offset(-8)
        }
        countLabel.snp.makeConstraints {
            $0.trailing.equalTo(chevronImageView.snp.leading).offset(-4)
            $0.centerY.equalToSuperview()
        }
        chevronImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(20)
        }
    }
}

extension WidgetPresetCell {
    func config(title: String, count: Int) {
        titleLabel.text = title
        countLabel.text = "상품 \(count)/5"
        
        var backgroundConfig = UIBackgroundConfiguration.clear()
        backgroundConfig.backgroundColor = .white
        backgroundConfig.cornerRadius = 8
        backgroundConfig.strokeColor = .gray100
        backgroundConfig.strokeWidth = 1
        backgroundConfiguration = backgroundConfig
    }
}
