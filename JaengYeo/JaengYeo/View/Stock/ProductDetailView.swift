//
//  ProductDetailView.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/16/26.
//

import UIKit
import Then
import SnapKit
import RxSwift

/// 상세화면 전용 구조체
// TODO: 추후 ViewModel로 이관예정
struct ProductDetailDisplayModel {
    let headerImage: UIImage?
    let productName: String
    let productCount: String

    let mainInfos: [ProductDetailInfoItem]
    let subInfos: [ProductDetailInfoItem]
}

struct ProductDetailInfoItem {
    let icon: UIImage?
    let title: String
    let detail: String
}


final class ProductDetailView: UIView {
    
    
    //MARK: - Components
    let productImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 8
    }
    let productNameLabel = StyledLabel(config: .titleBold24)
    
    let countLabel = StyledLabel(
        config: LabelConfiguration.body12.updatingColor(color: .accent)
    )
    
    let countTitleLabel = StyledLabel(
        config: LabelConfiguration.titleSemi20.updatingColor(color: .gray500))
    
    let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
        $0.alwaysBounceVertical = true
    }
    
    let scrollContentView = UIView()

    let mainStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 16
        $0.distribution = .equalSpacing
        $0.alignment = .leading
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 8
        $0.isLayoutMarginsRelativeArrangement = true
        $0.layer.borderColor = UIColor.gray100.cgColor
        $0.layer.borderWidth = 1
    }
    
    let subStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 16
        $0.distribution = .equalSpacing
        $0.alignment = .leading
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 8
        $0.isLayoutMarginsRelativeArrangement = true
        $0.layer.borderColor = UIColor.gray100.cgColor
        $0.layer.borderWidth = 1
    }
    
    let deleteButton = StyledButton(
        title: "삭제",
        titleConfiguration: .redTitle,
        appearanceConfiguration: .redAppearance
    ).then {
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 8
    }
    
    let modifyButton = StyledButton(
        title: "수정하기",
        titleConfiguration: .defaultTitle,
        appearanceConfiguration: .defaultAppearance
    ).then {
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 8
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


extension ProductDetailView {
    
    func updateUI(displayModel: ProductDetailDisplayModel) {
        productImageView.image = displayModel.headerImage
        productNameLabel.text = displayModel.productName
        countLabel.text = displayModel.productCount
        countTitleLabel.text = "개"

        mainStackView.arrangedSubviews.forEach {
            mainStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        subStackView.arrangedSubviews.forEach {
            subStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        displayModel.mainInfos.forEach { item in
            let view = createInfoView(
                image: item.icon ?? UIImage(),
                title: item.title,
                detail: item.detail
            )
            mainStackView.addArrangedSubview(view)
        }

        guard displayModel.subInfos.count == 0 else {
            subStackView.isHidden = true
            return
        }
        
        displayModel.subInfos.forEach { item in
            let view = createInfoView(
                image: item.icon ?? UIImage(),
                title: item.title,
                detail: item.detail
            )
            subStackView.addArrangedSubview(view)
        }
    }
    
    private func createInfoView(
        image: UIImage,
        title: String,
        detail: String )
    -> ProductInfoView {
        let infoView = ProductInfoView()
        infoView.updateUI(image: image, title: title, detail: detail)
        return infoView
    }
    
}

extension ProductDetailView {
    private func configureUI() {
        
        let topView = UIView()
        let bottomView = UIView()
                
        topView.addSubview(productImageView)
        topView.addSubview(productNameLabel)
        topView.addSubview(countLabel)
        topView.addSubview(countTitleLabel)
        bottomView.addSubview(deleteButton)
        bottomView.addSubview(modifyButton)
        
        scrollContentView.addSubview(topView)
        scrollContentView.addSubview(mainStackView)
        scrollContentView.addSubview(subStackView)
        
        addSubview(topView)
        addSubview(scrollContentView)
        addSubview(bottomView)
        
        topView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(66)
        }
        
        scrollView.snp.makeConstraints {
            $0.top.leading.trailing.equalTo(safeAreaLayoutGuide)
            $0.bottom.equalTo(bottomView.snp.top).offset(-16)
        }
        scrollContentView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            $0.width.equalTo(scrollView.frameLayoutGuide)
        }
        
        bottomView.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.leading.equalToSuperview()
            $0.trailing.equalToSuperview()
        }
        
        productImageView.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalToSuperview().offset(16)
            $0.size.equalTo(36)
        }
        
        productNameLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalTo(productImageView.snp.trailing).offset(8)
            $0.trailing.equalTo(countTitleLabel.snp.leading)
        }
        
        countTitleLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview().offset(16)
        }
        
        countLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalTo(countTitleLabel.snp.leading)
        }
        
        mainStackView.snp.makeConstraints {
            $0.top.equalTo(topView.snp.bottom)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().inset(16)
        }
        
        subStackView.snp.makeConstraints {
            $0.top.equalTo(mainStackView.snp.bottom).offset(16)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview()
        }
    
        deleteButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalToSuperview().offset(16)
            $0.width.equalTo(89)
            $0.height.equalTo(44)
        }
        
        modifyButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalTo(deleteButton.snp.trailing).offset(16)
            $0.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(44)
        }
    }
}
