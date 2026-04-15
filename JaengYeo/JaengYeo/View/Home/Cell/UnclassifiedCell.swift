//
//  UnclassifiedCell.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/15/26.
//

import UIKit
import SnapKit
import Then

final class UnclassifiedCell: UICollectionViewCell {
    static let id = "UnclassifiedCell"
    
    private let warningImageView = UIImageView().then {
        $0.image = UIImage(named: "warningIcon")
        $0.tintColor = .gray500
        $0.contentMode = .scaleAspectFit
    }
    
    private let labelStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 4
        $0.alignment = .leading
    }
    
    private let titleLabel = UILabel().then {
        $0.font = LabelConfiguration.bodyMedium14.font
        $0.textColor = .gray800
    }
    
    private let subtitleLabel = UILabel().then {
        $0.text = "카테고리를 설정해주세요"
        $0.font = LabelConfiguration.body12.font
        $0.textColor = .gray500
    }
    
    private let chevronImageView = UIImageView().then {
        $0.image = .arrowIcon
        $0.tintColor = .gray300
        $0.contentMode = .scaleAspectFit
        $0.transform = CGAffineTransform(scaleX: -1, y: 1)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .gray50
        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
    }
}

extension UnclassifiedCell {
    private func setLayout() {
        [titleLabel, subtitleLabel].forEach { labelStackView.addArrangedSubview($0) }
        [warningImageView, labelStackView, chevronImageView].forEach { contentView.addSubview($0) }
        
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalTo(67)
        }
        warningImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(24)
        }
        labelStackView.snp.makeConstraints {
            $0.leading.equalTo(warningImageView.snp.trailing).offset(16)
            $0.centerY.equalToSuperview()
        }
        chevronImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(24)
        }
    }
}

extension UnclassifiedCell {
    func config(count: Int) {
        titleLabel.text = "미분류 상품 \(count)개"
    }
}
