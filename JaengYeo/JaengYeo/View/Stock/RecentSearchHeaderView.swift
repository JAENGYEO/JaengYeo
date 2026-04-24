//
//  RecentSearchHeaderView.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/23/26.
//

import RxSwift
import SnapKit
import Then
import UIKit

final class RecentSearchHeaderView: UICollectionReusableView {

    var disposeBag = DisposeBag()

    private let titleLabel = UILabel().then {
        $0.text = "최근 검색어"
        $0.font = LabelConfiguration.bodyMedium14.font
        $0.textColor = .gray800
    }

    let deleteAllButton = UIButton(type: .system).then {
        $0.setTitle("전체 삭제", for: .normal)
        $0.titleLabel?.font = LabelConfiguration.body12.font
        $0.setTitleColor(.gray500, for: .normal)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }

    private func setLayout() {
        [titleLabel, deleteAllButton].forEach { addSubview($0) }

        titleLabel.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
        }

        deleteAllButton.snp.makeConstraints {
            $0.trailing.centerY.equalToSuperview()
        }
    }
}
