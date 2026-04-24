//
//  OnboardingFourthView.swift
//  JaengYeo
//
//  Created by Codex on 4/23/26.
//

import SnapKit
import Then
import UIKit

final class OnboardingFourthView: UIView {

    //MARK: - Components
    private let titleLabel = StyledLabel(config: .titleSemi20).then {
        $0.numberOfLines = 0
        $0.attributedText = OnboardingFourthView.makeTitle(
            primary: "나의 재고를",
            accent: "편리하게 관리해요"
        )
    }

    private let descriptionLabel = StyledLabel(config: .body14).then {
        $0.numberOfLines = 0
        $0.attributedText = OnboardingFourthView.makeDescription(
            "내가 원하는 방식대로\n재고 분류와 관리를 더 자유롭게 하세요!"
        )
    }

    private let imageView = UIImageView().then {
        $0.image = UIImage(named: "Onbording4")
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
private extension OnboardingFourthView {
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
