//
//  OnboardingThirdView.swift
//  JaengYeo
//
//  Created by Codex on 4/23/26.
//

import SnapKit
import Then
import UIKit

final class OnboardingThirdView: UIView {

    //MARK: - Components
    private let titleLabel = StyledLabel(config: .titleSemi20).then {
        $0.numberOfLines = 0
        $0.attributedText = OnboardingThirdView.makeTitle(
            primary: "카메라 인식과 빠른 등록을 통해",
            accent: "쉽고 간편하게 등록해요"
        )
    }

    private let descriptionLabel = StyledLabel(config: .body14).then {
        $0.numberOfLines = 0
        $0.attributedText = OnboardingThirdView.makeDescription(
            "다양한 방법으로 아이템을 추가하고,\n빠른 등록으로 번거로움을 줄여요"
        )
    }

    private let firstImageView = UIImageView().then {
        $0.image = UIImage(named: "Onbording3-1")
        $0.contentMode = .scaleAspectFit
    }

    private let secondImageView = UIImageView().then {
        $0.image = UIImage(named: "Onbording3-2")
        $0.contentMode = .scaleAspectFit
    }

    private let bottomTitleLabel = StyledLabel(config: .bodyMedium14).then {
        $0.numberOfLines = 1
        $0.attributedText = NSAttributedString(
            string: "빠른 등록?",
            attributes: [
                .font: LabelConfiguration.bodyMedium14.font,
                .foregroundColor: UIColor.accent,
                .kern: LabelConfiguration.bodyMedium14.kern
            ]
        )
    }

    private let bottomDescriptionLabel = StyledLabel(config: .body14).then {
        $0.numberOfLines = 0
        $0.attributedText = OnboardingThirdView.makeDescription(
            "연속으로 촬영해 자동으로 등록되는 기능"
        )
    }

    //MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//MARK: - Configure UI
private extension OnboardingThirdView {
    func configureUI() {
        backgroundColor = .white

        addSubview(titleLabel)
        addSubview(descriptionLabel)
        addSubview(firstImageView)
        addSubview(secondImageView)
        addSubview(bottomTitleLabel)
        addSubview(bottomDescriptionLabel)

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(72)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        descriptionLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        firstImageView.snp.makeConstraints {
            $0.top.equalTo(descriptionLabel.snp.bottom).offset(72)
            $0.centerX.equalToSuperview()
            $0.size.equalTo(CGSize(width: 343, height: 75))
        }

        secondImageView.snp.makeConstraints {
            $0.top.equalTo(firstImageView.snp.bottom).offset(72)
            $0.centerX.equalToSuperview()
            $0.size.equalTo(CGSize(width: 343, height: 87))
        }

        bottomTitleLabel.snp.makeConstraints {
            $0.top.equalTo(secondImageView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        bottomDescriptionLabel.snp.makeConstraints {
            $0.top.equalTo(bottomTitleLabel.snp.bottom).offset(2)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
    }

    static func makeTitle(
        primary: String,
        accent: String
    ) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(
            string: "\(primary)\n",
            attributes: [
                .font: LabelConfiguration.titleSemi20.font,
                .foregroundColor: UIColor.gray800,
                .kern: LabelConfiguration.titleSemi20.kern
            ]
        )

        attributedString.append(
            NSAttributedString(
                string: accent,
                attributes: [
                    .font: LabelConfiguration.titleSemi20.font,
                    .foregroundColor: UIColor.accent,
                    .kern: LabelConfiguration.titleSemi20.kern
                ]
            )
        )

        return attributedString
    }

    static func makeDescription(_ text: String) -> NSAttributedString {
        NSAttributedString(
            string: text,
            attributes: [
                .font: LabelConfiguration.body14.font,
                .foregroundColor: UIColor.gray300,
                .kern: LabelConfiguration.body14.kern
            ]
        )
    }
}
