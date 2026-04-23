//
//  RecentSearchCell.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/23/26.
//

import UIKit
import SnapKit
import Then
import RxSwift

final class RecentSearchCell: UICollectionViewCell {
    static let id = "RecentSearchCell"
    
    var disposeBag = DisposeBag()
    
    private let titleLabel = UILabel().then {
        $0.font = LabelConfiguration.bodyMedium12.font
        $0.textColor = .gray800
    }
    
    let deleteButton = UIButton(type: .custom).then {
        let image = UIImage(named: "closeIcon")?.withRenderingMode(.alwaysTemplate)
        $0.setImage(image, for: .normal)
        $0.tintColor = .gray300
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
        titleLabel.text = nil
        disposeBag = DisposeBag()
    }
}

extension RecentSearchCell {
    private func setLayout() {
        contentView.layer.cornerRadius = 17
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.gray100.cgColor
        contentView.clipsToBounds = true
        
        [titleLabel, deleteButton].forEach { contentView.addSubview($0) }
        
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
        }
        
        deleteButton.snp.makeConstraints {
            $0.leading.equalTo(titleLabel.snp.trailing).offset(4)
            $0.trailing.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(14)
        }
    }
}

extension RecentSearchCell {
    func config(keyword: String) {
        titleLabel.text = keyword
    }
}
