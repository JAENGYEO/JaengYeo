//
//  EmptyProductCardView.swift
//  JaengYeo
//
//  Created by 손영빈 on 5/1/26.
//

import UIKit
import SnapKit
import Then

final class EmptyProductCardView: UIView {
    private let iconImageView = UIImageView().then {
        $0.image = .warningIcon
        $0.tintColor = .gray500
        $0.contentMode = .scaleAspectFit
    }
    private let titleLabel = UILabel().then {
        $0.text = "프리셋에 추가된 상품이 없어요!"
        $0.font = LabelConfiguration.bodyMedium14.font
        $0.textColor = .gray800
        $0.numberOfLines = 1
    }
    private let descriptionLabel = UILabel().then {
        $0.text = "추가 버튼을 눌러서 위젯에 보일 상품을 추가해주세요"
        $0.font = LabelConfiguration.body12.font
        $0.textColor = .gray500
        $0.numberOfLines = 1
    }
    private let textStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 4
        $0.alignment = .leading
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setAttributes()
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension EmptyProductCardView {
    private func setAttributes() {
        backgroundColor = .gray50
        layer.cornerRadius = 8
        clipsToBounds = true
    }
    private func setLayout() {
        [titleLabel, descriptionLabel].forEach { textStackView.addArrangedSubview($0) }
        [iconImageView, textStackView].forEach { addSubview($0) }
        
        iconImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(24)
        }
        textStackView.snp.makeConstraints {
            $0.leading.equalTo(iconImageView.snp.trailing).offset(12)
            $0.trailing.lessThanOrEqualToSuperview().offset(-16)
            $0.top.bottom.equalToSuperview().inset(16)
        }
    }
}
