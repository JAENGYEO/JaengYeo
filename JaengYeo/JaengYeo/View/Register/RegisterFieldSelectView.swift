//
//  RegisterFieldSelectView.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/12/26.
//

import UIKit
import SnapKit
import Then

final class RegisterFieldSelectView: UIView {

    // MARK: 바텀 시트 시 뒷 배경
    let dimmingView = UIView().then {
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        $0.alpha = 0
    }

    // MARK: 콘텐츠 컨테이너
    let contentView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 20
        $0.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        $0.clipsToBounds = true
    }

    private let handleView = UIView().then {
        $0.backgroundColor = .gray300
        $0.layer.cornerRadius = 2.5
    }

    // MARK: 필드 목록
    let fieldStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 8
    }

    // MARK: 하단 버튼 (리셋, 확인)
    let resetButton = UIButton().then {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "arrow.counterclockwise")
        config.title = "초기화"
        config.imagePadding = 4
        config.baseForegroundColor = .gray300
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attr in
            var out = attr
            out.font = LabelConfiguration.bodyMedium14.font
            return out
        }
        $0.configuration = config
    }

    let confirmButton = UIButton().then {
        $0.setTitle("완료", for: .normal)
        $0.titleLabel?.font = LabelConfiguration.bodyMedium14.font
        $0.backgroundColor = .accent
        $0.layer.cornerRadius = 12
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension RegisterFieldSelectView {
    private func setLayout() {
        [handleView, fieldStackView, resetButton, confirmButton].forEach { contentView.addSubview($0) }
        [dimmingView, contentView].forEach { addSubview($0) }

        dimmingView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        contentView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.top.greaterThanOrEqualToSuperview()
        }
        handleView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(40)
            $0.height.equalTo(5)
        }
        fieldStackView.snp.makeConstraints {
            $0.top.equalTo(handleView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        confirmButton.snp.makeConstraints {
            $0.width.equalTo(238)
            $0.height.equalTo(44)
            $0.trailing.equalToSuperview().offset(-16)
            $0.bottom.equalTo(contentView.safeAreaLayoutGuide).offset(-8)
            $0.top.equalTo(fieldStackView.snp.bottom).offset(16)
        }
        resetButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalTo(confirmButton)
        }
    }

    func makeFieldRow(field: RegisterOptionField, isSelected: Bool) -> UIView {
        let container = UIView().then {
            $0.layer.borderWidth = 1
            $0.layer.cornerRadius = 8
            $0.layer.borderColor = UIColor.gray100.cgColor
        }
        let titleLabel = UILabel().then {
            $0.text = field.title
            $0.font = LabelConfiguration.bodyMedium14.font
            $0.textColor = .gray800
        }
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        let indicator = UIImageView().then {
            $0.image = isSelected
            ? UIImage(systemName: "checkmark.circle.fill", withConfiguration: symbolConfig)
            : UIImage(systemName: "circle.fill", withConfiguration: symbolConfig)
            $0.tintColor = isSelected ? .accent : .gray50
            $0.layer.cornerRadius = 12
            $0.layer.borderWidth = isSelected ? 0 : 1
            $0.layer.borderColor = UIColor.gray100.cgColor
        }

        [titleLabel, indicator].forEach { container.addSubview($0) }
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
        }
        indicator.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(24)
        }
        container.snp.makeConstraints {
            $0.height.equalTo(48)
        }
        return container
    }
}
