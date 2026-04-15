//
//  HomeSectionHeaderView.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/15/26.
//

import UIKit
import SnapKit
import Then

final class HomeSectionHeaderView: UICollectionReusableView {
    static let id = "HomeSectionHeaderView"
    
    private let titleLabel = UILabel().then {
        $0.font = LabelConfiguration.titleSemi16.font
        $0.textColor = .gray800
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.top.bottom.equalToSuperview().inset(8)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension HomeSectionHeaderView {
    func config(title: String) {
        titleLabel.text = title
    }
}
