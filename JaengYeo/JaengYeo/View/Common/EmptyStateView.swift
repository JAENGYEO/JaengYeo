//
//  EmptyStateView.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/15/26.
//

import UIKit
import SnapKit
import Then

final class EmptyStateView: UIView {
    
    private let illustrationImageView = UIImageView().then {
        $0.image = .illustrator
        $0.contentMode = .scaleAspectFit
    }
    
    private let titleLabel = UILabel().then {
        $0.text = "등록된 제품이 없어요"
        $0.font = LabelConfiguration.titleSemi18.font
        $0.textColor = .gray800
        $0.textAlignment = .center
    }
    
    private let descriptionLabel = UILabel().then {
        $0.text = "제품을 등록하고 쟁여를 시작해요!"
        $0.font = LabelConfiguration.bodyMedium14.font
        $0.textColor = .gray500
        $0.textAlignment = .center
    }
    
    let actionButton = UIButton().then {
        $0.titleLabel?.font = LabelConfiguration.body14.font
        $0.setTitle("등록하러 가기", for: .normal)
        $0.setTitleColor(.white, for: .normal)
        $0.backgroundColor = .accent
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
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

extension EmptyStateView {
    private func setLayout() {
        [illustrationImageView, titleLabel, descriptionLabel, actionButton].forEach { addSubview($0) }
        
        illustrationImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.height.equalTo(210)
            $0.width.equalTo(285)
        }
        descriptionLabel.snp.makeConstraints {
            $0.bottom.equalTo(illustrationImageView.snp.top).offset(-40)
            $0.centerX.equalToSuperview()
        }
        titleLabel.snp.makeConstraints {
            $0.bottom.equalTo(descriptionLabel.snp.top).offset(-8)
            $0.centerX.equalToSuperview()
        }
        actionButton.snp.makeConstraints {
            $0.top.equalTo(illustrationImageView.snp.bottom).offset(40)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(48)
        }
    }
}

extension EmptyStateView {
    func config(title: String, description: String, buttonTitle: String? = nil) {
        titleLabel.text = title
        descriptionLabel.text = description
        if let buttonTitle {
            actionButton.isHidden = false
            actionButton.setTitle(buttonTitle, for: .normal)
        } else {
            actionButton.isHidden = true
        }
    }
}
