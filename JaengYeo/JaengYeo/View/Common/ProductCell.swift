//
//  Untitled.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/8/26.
//

import UIKit
import SnapKit
import Then
import RxCocoa

final class ProductCell: UICollectionViewCell {
    
    //MARK: - Componenets
    /// 아이템 이미지 뷰
    let productImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 8
    }
    
    /// 아이템 타이틀
    let productTitleLabel = StyledLabel(config: .bodyMedium14)
    
    /// 아이템 카운트
    let productCountLabel = StyledLabel(config: .titleSemi18)
    
    /// 아이템 정보 스텍
    let productDesciptStack = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 4
        $0.alignment = .leading
        $0.distribution = .equalSpacing
    }
    
    //MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ProductCell {
    
    func configureUI() {
     
        let productMainStack = UIStackView().then {
            $0.axis = .horizontal
            $0.spacing = 16
            $0.alignment = .leading
            $0.distribution = .fillProportionally
        }
        
        let productInfoStack = UIStackView().then {
            $0.axis = .vertical
            $0.spacing = 4
            $0.alignment = .leading
            $0.distribution = .fillProportionally
        }
    
        let productCountStack = UIStackView().then {
            $0.axis = .horizontal
            $0.spacing = 0
            $0.alignment = .center
            $0.distribution = .equalSpacing
        }
        
        let countLabel = StyledLabel(config: .body12.updatingColor(color: .gray300))
        
        productCountStack.addArrangedSubview(productCountLabel)
        productCountStack.addArrangedSubview(countLabel)
        
        productInfoStack.addArrangedSubview(productTitleLabel)
        productInfoStack.addArrangedSubview(productDesciptStack)
        productMainStack.addArrangedSubview(productImageView)
        productInfoStack.addArrangedSubview(productInfoStack)
        
        contentView.addSubview(productInfoStack)
        contentView.addSubview(productCountStack)
        
        
        productMainStack.snp.makeConstraints{
            $0.top.equalToSuperview().
        }
    }
}

#Preview{
    ProductCell()
}
