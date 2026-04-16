//
//  ProductInfoView.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/16/26.
//

import UIKit
import Then
import SnapKit
import RxSwift

final class ProductInfoView: UIView {
    
    //MARK: - Components
    private let iconImageView = UIImageView().then {
        $0.backgroundColor = .clear
    }
    
    private let titleLabel = StyledLabel(
        config: LabelConfiguration.body12.updatingColor(color: .gray300)
    )
    
    private let detailLabel = StyledLabel(config: .titleSemi16)
   
    private let modifyButton = StyledButton(
        title: "수정하기",
        titleConfiguration: .defaultTitle,
        appearanceConfiguration: .defaultAppearance
    )
    
    //MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension ProductInfoView {
    func updateUI(image: UIImage, title: String, detail: String) {
        iconImageView.image = image
        titleLabel.text = title
        detailLabel.text = detail
    }
}

extension ProductInfoView {
    private func configureUI() {
         
        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(detailLabel)
        
        iconImageView.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalToSuperview()
            $0.size.equalTo(24)
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.equalTo(iconImageView.snp.trailing).offset(16)
            $0.trailing.equalToSuperview()
        }
            
        detailLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel).offset(4)
            $0.leading.equalTo(iconImageView.snp.trailing).offset(16)
            $0.trailing.bottom.equalToSuperview()
        }
    }
}
