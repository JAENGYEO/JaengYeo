//
//  CategorySummaryCell.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/15/26.
//

import UIKit
import SnapKit
import Then

final class CategorySummaryCell: UICollectionViewCell {
    static let id = "CategorySummaryCell"
    
    private let titleLabel = UILabel().then {
        $0.font = LabelConfiguration.bodyMedium14.font
        $0.textColor = .gray800
    }
    
    private let countLabel = UILabel().then {
        $0.font = LabelConfiguration.titleBold24.font
        $0.textColor = .accent
    }
    
    private let countUnitLabel = UILabel().then {
        $0.text = "개"
        $0.font = LabelConfiguration.body12.font
        $0.textColor = .gray500
    }
    
    private let midCategoryView = CategorySubCard(title: "중분류", iconName: "locationIcon")
    private let subCategoryView = CategorySubCard(title: "소분류", iconName: "filterIcon")
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.gray100.cgColor
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        countLabel.text = nil
    }
}

extension CategorySummaryCell {
    private func setLayout() {
        [titleLabel, countLabel, countUnitLabel, midCategoryView, subCategoryView].forEach { contentView.addSubview($0) }
        titleLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().offset(12)
        }
        countLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.leading.equalToSuperview().offset(12)
        }
        countUnitLabel.snp.makeConstraints {
            $0.leading.equalTo(countLabel.snp.trailing)
            $0.bottom.equalTo(countLabel.snp.bottom).offset(-4)
        }

        midCategoryView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(8)
            $0.bottom.equalToSuperview().offset(-8)
            $0.width.equalToSuperview().multipliedBy(0.44)
            $0.height.equalTo(51)
        }
        subCategoryView.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-8)
            $0.bottom.equalToSuperview().offset(-8)
            $0.width.equalToSuperview().multipliedBy(0.44)
            $0.height.equalTo(51)
        }
    }
}

extension CategorySummaryCell {
    func config(name: String, totalCount: Int, midCount: Int, subCount: Int) {
        titleLabel.text = name
        countLabel.text = "\(totalCount)"
        midCategoryView.config(count: midCount)
        subCategoryView.config(count: subCount)
    }
}
