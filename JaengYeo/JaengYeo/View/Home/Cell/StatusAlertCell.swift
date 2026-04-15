//
//  StatusAlertCell.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/15/26.
//

import UIKit
import SnapKit
import Then

final class StatusAlertCell: UICollectionViewCell {
    static let id = "StatusAlertCell"
    
    private let iconImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
    }
    
    private let titleLabel = UILabel().then {
        $0.font = LabelConfiguration.titleSemi16.font
        $0.textColor = .gray800
    }
    
    private let countLabel = UILabel().then {
        $0.font = LabelConfiguration.bodyMedium14.font
    }
    
    private let progressBackView = UIView().then {
        $0.backgroundColor = .gray100
        $0.layer.cornerRadius = 3
        $0.clipsToBounds = true
    }
    
    private let progressFillView = UIView().then {
        $0.layer.cornerRadius = 3
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.gray100.cgColor
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        countLabel.text = nil
        iconImageView.image = nil
        iconImageView.tintColor = nil
        progressFillView.backgroundColor = nil
    }
}

extension StatusAlertCell {
    private func setLayout() {
        [iconImageView, titleLabel, countLabel, progressBackView].forEach { contentView.addSubview($0) }
        progressBackView.addSubview(progressFillView)
        iconImageView.snp.makeConstraints {
            $0.top.leading.equalToSuperview().offset(16)
            $0.size.equalTo(20)
        }
        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(iconImageView.snp.trailing).offset(4)
            $0.centerY.equalTo(iconImageView)
        }
        countLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalTo(iconImageView)
        }
        progressBackView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.top.equalTo(iconImageView.snp.bottom).offset(8)
            $0.height.equalTo(6)
            $0.bottom.equalToSuperview().offset(-16)
        }
        progressFillView.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.width.equalToSuperview().multipliedBy(0)
        }
    }
}

extension StatusAlertCell {
    func config(title: String, count: Int, ratio: Float, color: UIColor, icon: String) {
        titleLabel.text = title
        countLabel.text = "\(count)개"
        countLabel.textColor = color
        iconImageView.image = UIImage(named: icon)
        iconImageView.tintColor = color
        progressFillView.backgroundColor = color
        progressFillView.snp.remakeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.width.equalToSuperview().multipliedBy(CGFloat(ratio))
        }
    }
}
