//
//  CategorySubCard.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/15/26.
//

import UIKit
import SnapKit
import Then

final class CategorySubCard: UIView {
    private let titleLabel = UILabel().then {
        $0.font = LabelConfiguration.body12.font
        $0.textColor = .white
    }
    
    private let countLabel = UILabel().then {
        $0.font = LabelConfiguration.titleSemi16.font
        $0.textColor = .white
    }
    
    private let unitLabel = UILabel().then {
        $0.text = "개"
        $0.font = LabelConfiguration.body12.font
        $0.textColor = .white
    }
    
    private let iconImageView = UIImageView().then {
        $0.tintColor = .white
        $0.contentMode = .scaleAspectFit
    }
    
    init(title: String, iconName: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        iconImageView.image = UIImage(named: iconName)
        backgroundColor = .accent
        layer.cornerRadius = 8
        clipsToBounds = true
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension CategorySubCard {
    private func setLayout() {
        [titleLabel, countLabel, unitLabel, iconImageView].forEach { addSubview($0) }
        
        titleLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().offset(8)
        }
        countLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(8)
            $0.bottom.equalToSuperview().offset(-8)
        }
        unitLabel.snp.makeConstraints {
            $0.leading.equalTo(countLabel.snp.trailing)
            $0.bottom.equalTo(countLabel.snp.bottom).offset(-2)
        }
        iconImageView.snp.makeConstraints {
            $0.trailing.bottom.equalToSuperview().offset(-8)
            $0.size.equalTo(20)
        }
    }
}

extension CategorySubCard {
    func config(count: Int) {
        countLabel.text = "\(count)"
    }
}
