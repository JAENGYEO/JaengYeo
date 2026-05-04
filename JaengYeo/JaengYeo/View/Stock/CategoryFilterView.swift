//
//  CategoryFilterView.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/9/26.
//


import UIKit
import SnapKit
import Then

final class CategoryFilterView: UIView {
    
    
    let midCategoryButton = StyledButton(title: "보관 위치",
                                         titleConfiguration: .categoryTitle,
                                         appearanceConfiguration: .categoryAppearance)
    
    let subCategoryButton = StyledButton(title: "종류",
                                         titleConfiguration: .categoryTitle,
                                         appearanceConfiguration: .categoryAppearance)
    
    let categoryEditButton = StyledButton(title: "분류 편집",
                                          titleConfiguration: .textTitle12,
                                          appearanceConfiguration: .textAppearance)
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


extension CategoryFilterView {
    func configureUI() {
        
        addSubview(midCategoryButton)
        addSubview(subCategoryButton)
        addSubview(categoryEditButton)
        
        
        midCategoryButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalToSuperview()
            $0.width.equalTo(96)
            $0.height.equalTo(30)
        }
        
        subCategoryButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalTo(midCategoryButton.snp.trailing).offset(8)
            $0.width.equalTo(96)
            $0.height.equalTo(30)
        }
        
        categoryEditButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview()
        }
    }
}

#Preview {
    CategoryFilterView()
}

