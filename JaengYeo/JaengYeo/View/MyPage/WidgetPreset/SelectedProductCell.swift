//
//  SelectedProductCell.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/30/26.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

final class SelectedProductCell: UICollectionViewCell {
    static let id = "SelectedProductCell"
    
    private var disposeBag = DisposeBag()
    
    private let titleLabel = UILabel().then {
        $0.font = LabelConfiguration.titleSemi16.font
        $0.textColor = .gray800
        $0.numberOfLines = 1
    }
    private let categoryLabel = UILabel().then {
        $0.font = LabelConfiguration.body14.font
        $0.textColor = .gray500
        $0.numberOfLines = 1
    }
    private let removeButton = UIButton().then {
        $0.setImage(UIImage(systemName: "xmark.circle.fill"),for: .normal)
        $0.tintColor = .gray400
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
        titleLabel.text = nil
        categoryLabel.text = nil
    }
}

extension SelectedProductCell {
    private func setLayout() {
        backgroundColor = .white
        [titleLabel, categoryLabel, removeButton].forEach { contentView.addSubview($0) }
        
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.top.equalToSuperview().offset(8)
            $0.trailing.lessThanOrEqualTo(removeButton.snp.leading).offset(-8)
        }
        categoryLabel.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.top.equalTo(titleLabel.snp.bottom).offset(2)
            $0.trailing.lessThanOrEqualTo(removeButton.snp.leading).offset(-8)
        }
        removeButton.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.size.equalTo(24)
        }
    }
}

extension SelectedProductCell {
    func config(title: String, category: String) {
        titleLabel.text = title
        categoryLabel.text = category
    }
    func bindRemoveButtonTap(onNext: @escaping () -> Void) {
        removeButton.rx.tap
            .bind(onNext: onNext)
            .disposed(by: disposeBag)
    }
}
