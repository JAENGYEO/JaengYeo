//
//  OnboardingSixthView.swift
//  JaengYeo
//
//  Created by Codex on 5/4/26.
//

import SnapKit
import Then
import UIKit

final class OnboardingSixthView: UIView {

    //MARK: - Components
    private let titleLabel = StyledLabel(config: .titleSemi20).then {
        $0.numberOfLines = 0
        $0.attributedText = OnboardingSixthView.makeTitle(
            primary: "다양한 위젯으로",
            accent: "쉽고 빠르게 관리해요"
        )
    }

    private let descriptionLabel = StyledLabel(config: .body14).then {
        $0.numberOfLines = 0
        $0.attributedText = OnboardingSixthView.makeDescription(
            "마이페이지에서 내가 자주 쓰는 기능을\n위젯으로 만들어 빠르게 재고를 관리할 수 있어요"
        )
    }

    private let imageView = UIImageView().then {
        $0.image = UIImage(named: "Onbording6")
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
private extension OnboardingSixthView {
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
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(imageView.snp.width).multipliedBy(358.0 / 345.0)
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
