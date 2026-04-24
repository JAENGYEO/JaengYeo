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


final class ProductDetailView: UIView {
    
    
    //MARK: - Components
    let productImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 8
    }.then {
        $0.image = UIImage(named: "iconSelectIcon")
    }
    
    
    let productNameLabel = StyledLabel(config: .titleBold24).then {
        $0.text = "상품명"
        $0.numberOfLines = 1
        $0.lineBreakMode = .byTruncatingTail
    }
    
    let countLabel = StyledLabel(
        config: LabelConfiguration.titleBold28.updatingColor(color: .accent)
    ).then {
        $0.text = "00"
    }
    
    let countTitleLabel = StyledLabel(
        config: LabelConfiguration.titleSemi20.updatingColor(color: .gray500))
        .then {
            $0.text = "개"
        }

    let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
        $0.alwaysBounceVertical = true
        $0.backgroundColor = .white
    }
    
    let scrollContentView = UIView().then {
        $0.backgroundColor = .white
    }

    let mainStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 16
        $0.distribution = .fill
        $0.alignment = .fill
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 8
        $0.isLayoutMarginsRelativeArrangement = true
        $0.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 16,
            leading: 16,
            bottom: 16,
            trailing: 16
        )
        $0.layer.borderColor = UIColor.gray100.cgColor
        $0.layer.borderWidth = 1
    }
    
    let subStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 16
        $0.distribution = .fill
        $0.alignment = .fill
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 8
        $0.isLayoutMarginsRelativeArrangement = true
        $0.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 16,
            leading: 16,
            bottom: 16,
            trailing: 16
        )
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

        if displayModel.subInfos.isEmpty {
            subStackView.isHidden = true
        } else {
            subStackView.isHidden = false
            displayModel.subInfos.forEach { item in
                let view = createInfoView(
                    image: item.icon ?? UIImage(),
                    title: item.title,
                    detail: item.detail
                )
                subStackView.addArrangedSubview(view)
            }
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
        backgroundColor = .white

        let topView = UIView().then {
            $0.backgroundColor = .white
        }
        let bottomView = UIView().then {
            $0.backgroundColor = .white
        }
                
        topView.addSubview(productImageView)
        topView.addSubview(productNameLabel)
        topView.addSubview(countLabel)
        topView.addSubview(countTitleLabel)
        bottomView.addSubview(deleteButton)
        bottomView.addSubview(modifyButton)
        
        addSubview(scrollView)
        addSubview(bottomView)
        
        scrollView.addSubview(scrollContentView)
        scrollContentView.addSubview(topView)
        scrollContentView.addSubview(mainStackView)
        scrollContentView.addSubview(subStackView)
        
        scrollView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(bottomView.snp.top).offset(-16)
        }
        
        scrollContentView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            $0.width.equalTo(scrollView.frameLayoutGuide)
        }
        
        topView.snp.makeConstraints {
            $0.top.equalTo(scrollContentView)
            $0.leading.trailing.equalTo(scrollContentView)
            $0.height.equalTo(66)
        }
        
        
        
        bottomView.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.trailing.equalToSuperview()
            $0.bottom.equalTo(safeAreaLayoutGuide).inset(16)
            $0.height.equalTo(44)
        }
        
        productImageView.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalToSuperview().offset(16)
            $0.size.equalTo(36)
        }
        
        productNameLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalTo(productImageView.snp.trailing).offset(8)
            $0.trailing.lessThanOrEqualTo(countLabel.snp.leading).offset(-8)
        }
        
        countTitleLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview().inset(16)
        }
        
        countLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalTo(countTitleLabel.snp.leading)

        }
        
        mainStackView.snp.makeConstraints {
            $0.top.equalTo(topView.snp.bottom)
            $0.leading.equalTo(scrollContentView).offset(16)
            $0.trailing.equalTo(scrollContentView).inset(16)
        }
        
        subStackView.snp.makeConstraints {
            $0.top.equalTo(mainStackView.snp.bottom).offset(16)
            $0.leading.equalTo(scrollContentView).offset(16)
            $0.trailing.equalTo(scrollContentView).inset(16)
            $0.bottom.equalTo(scrollContentView)
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

#Preview {
    let viewController = UIViewController()
    let view = ProductDetailView()
    
    viewController.view.backgroundColor = .white
    viewController.view.addSubview(view)
    
    view.snp.makeConstraints {
        $0.edges.equalTo(viewController.view.safeAreaLayoutGuide)
    }
    
    view.updateUI(
        displayModel: ProductDetailDisplayModel(
            headerImage: UIImage(named: "iconSelectIcon"),
            productName: "식빵",
            productCount: "1",
            mainInfos: [
                ProductDetailInfoItem(
                    icon: UIImage(systemName: "square.grid.2x2"),
                    title: "대분류",
                    detail: "식재료"
                ),
                ProductDetailInfoItem(
                    icon: UIImage(systemName: "folder"),
                    title: "중분류",
                    detail: "빵"
                ),
                ProductDetailInfoItem(
                    icon: UIImage(systemName: "calendar"),
                    title: "등록일",
                    detail: "2026.04.17"
                )
            ],
            subInfos: [
                ProductDetailInfoItem(
                    icon: UIImage(systemName: "tag"),
                    title: "소분류",
                    detail: "베이커리"
                ),
                ProductDetailInfoItem(
                    icon: UIImage(systemName: "clock"),
                    title: "소비기한",
                    detail: "2026.04.25"
                )
            ]
        )
    )
    
    return viewController
}
