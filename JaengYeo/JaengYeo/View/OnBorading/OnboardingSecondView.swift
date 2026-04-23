//
//  OnboardingSecondView.swift
//  JaengYeo
//
//  Created by Codex on 4/23/26.
//

import SnapKit
import Then
import UIKit

final class OnboardingSecondView: UIView {

    //MARK: - Components
    private let titleLabel = StyledLabel(config: .titleSemi20).then {
        $0.numberOfLines = 0
        $0.attributedText = OnboardingSecondView.makeTitle(
            primary: "카메라 인식과 빠른 등록을 통해",
            accent: "쉽고 간편하게 등록해요"
        )
    }

    private let descriptionLabel = StyledLabel(config: .body14).then {
        $0.numberOfLines = 0
        $0.attributedText = OnboardingSecondView.makeDescription(
            "다양한 방법으로 아이템을 추가하고,\n빠른 등록으로 번거로움을 줄여요"
        )
    }

    private let imageView = UIImageView().then {
        $0.image = UIImage(named: "Onbording2")
        $0.contentMode = .scaleAspectFit
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
private extension OnboardingSecondView {
    func configureUI() {
        backgroundColor = .white

        addSubview(titleLabel)
        addSubview(descriptionLabel)
        addSubview(imageView)

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(72)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        descriptionLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        imageView.snp.makeConstraints {
            $0.top.equalTo(descriptionLabel.snp.bottom).offset(40)
            $0.centerX.equalToSuperview()
            $0.size.equalTo(CGSize(width: 160, height: 346))
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
