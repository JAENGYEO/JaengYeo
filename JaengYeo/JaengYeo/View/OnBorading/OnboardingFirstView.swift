//
//  OnboardingFirstView.swift
//  JaengYeo
//
//  Created by Codex on 4/23/26.
//

import SnapKit
import Then
import UIKit

final class OnboardingFirstView: UIView {

    //MARK: - Components
    private let titleLabel = StyledLabel(config: .titleSemi20).then {
        $0.numberOfLines = 0
        $0.attributedText = OnboardingFirstView.makeTitle(
            primary: "식자재와 생활용품을 관리하는",
            accent: "스마트 인벤토리"
        )
    }

    private let descriptionLabel = StyledLabel(config: .body14).then {
        $0.numberOfLines = 0
        $0.attributedText = OnboardingFirstView.makeDescription(
            "쟁여에 물건을 쟁여두면,\n집 안의 재고를 한눈에 확인하고\n깔끔하게 정리할 수 있어요!"
        )
    }

    private let imageView = UIImageView().then {
        $0.image = UIImage(named: "Onbording1")
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
private extension OnboardingFirstView {
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
            $0.top.equalTo(descriptionLabel.snp.bottom).offset(72)
            $0.centerX.equalToSuperview()
            $0.size.equalTo(CGSize(width: 285, height: 210))
            $0.bottom.equalToSuperview().inset(24)
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
                .foregroundColor: UIColor.gray800
            ]
        )

        attributedString.append(
            NSAttributedString(
                string: accent,
                attributes: [
                    .font: LabelConfiguration.titleSemi20.font,
                    .foregroundColor: UIColor.accent
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
                .foregroundColor: UIColor.gray300
            ]
        )
    }
}
