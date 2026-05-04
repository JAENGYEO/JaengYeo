//
//  RegisterCompleteView.swift
//  JaengYeo
//
//  Created by 손영빈 on 5/4/26.
//

import UIKit
import SnapKit
import Then

final class RegisterCompleteView: UIView {
    private let iconImageView = UIImageView().then {
        $0.image = .completeIcon
        $0.contentMode = .scaleAspectFit
    }
    private let titleLabel = UILabel().then {
        $0.text = "등록이 완료되었습니다"
        $0.font = LabelConfiguration.titleSemi18.font
        $0.textAlignment = .center
        $0.textColor = .gray800
    }
    private let descriptionLabel = UILabel().then {
        $0.text = "입력하신 정보가 재고 목록에 등록되었습니다"
        $0.font = LabelConfiguration.body14.font
        $0.textAlignment = .center
        $0.textColor = .gray500
    }
    private let infoStackView = UIStackView().then {
        $0.axis = .vertical
        $0.alignment = .center
        $0.spacing = 16
    }
    let stockButton = UIButton().then {
        $0.setTitle("재고 목록으로 가기", for: .normal)
        $0.titleLabel?.font = LabelConfiguration.bodyMedium14.font
        $0.setTitleColor(.white, for: .normal)
        $0.backgroundColor = .accent
        $0.layer.cornerRadius = 12
    }
    let homeButton = UIButton().then {
        $0.setTitle("홈으로", for: .normal)
        $0.titleLabel?.font = LabelConfiguration.bodyMedium14.font
        $0.setTitleColor(.gray800, for: .normal)
        $0.backgroundColor = .gray50
        $0.layer.cornerRadius = 12
    }
    private let buttonStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 8
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension RegisterCompleteView {
    private func setLayout() {
        backgroundColor = .white
        [iconImageView, titleLabel, descriptionLabel].forEach { infoStackView.addArrangedSubview($0) }
        [stockButton, homeButton].forEach { buttonStackView.addArrangedSubview($0) }
        [infoStackView, buttonStackView].forEach { addSubview($0) }
        
        infoStackView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-10)
        }
        iconImageView.snp.makeConstraints {
            $0.size.equalTo(80)
        }
        buttonStackView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(safeAreaLayoutGuide)
        }
        stockButton.snp.makeConstraints {
            $0.height.equalTo(48)
        }
        homeButton.snp.makeConstraints {
            $0.height.equalTo(48)
        }
    }
}
