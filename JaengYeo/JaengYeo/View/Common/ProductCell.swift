//
//  Untitled.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/8/26.
//

import UIKit
import SnapKit
import Then

//MARK: - Enum
/// 상품 셀 디자인 타입
enum ProductCellType {
    /// 기본 디자인
    case defaultType
    /// 상품 추가 정보 표기 디자인
    case detailType
    /// 등록 디자인
    case registType
}

/// 공용 상품 셀
final class ProductCell: UICollectionViewListCell{
    
    static let id = "ProductCell"
    
    // MARK: - Properties
    private var cellType: ProductCellType = .defaultType {
        didSet {
            switch cellType {
            case .defaultType:
                productSubDescriptionStack.isHidden = true
                productCountView.isHidden = false
                
            case .detailType:
                productSubDescriptionStack.isHidden = false
                productCountView.isHidden = false
                
            case .registType:
                productSubDescriptionStack.isHidden = true
                productCountView.isHidden = true
            }
        }
    }
    
    // MARK: - Components
    /// 아이템 이미지 뷰
    private let productImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 8
        $0.backgroundColor = .accent
    }
    
    /// 아이템 타이틀
    private let productTitleLabel = StyledLabel(config: .bodyMedium14).then {
        $0.text = "아이템 타이틀"
    }
    
    /// 아이템 카운트
    private let productCountLabel = StyledLabel(config: .titleSemi18).then {
        $0.text = "0"
    }
    
    /// 카운트 단위
    private let countUnitLabel = StyledLabel(config: .body12.updatingColor(color: .gray300)).then {
        $0.text = "개"
    }
    
    /// 메인 스택
    private let productMainStack = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 16
        $0.alignment = .center
        $0.distribution = .fill
    }
    
    /// 정보 스택
    private let productInfoStack = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 4
        $0.alignment = .leading
        $0.distribution = .fill
    }
    
    /// 메인 설명 스택
    private let productDescriptionStack = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 4
        $0.alignment = .center
        $0.distribution = .fill
    }
    
    /// 서브 설명 스택
    private let productSubDescriptionStack = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 4
        $0.alignment = .center
        $0.distribution = .fill
    }
    
    /// 수량 뷰
    private let productCountView = UIView()
    
    // MARK: - Init
    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


}

// MARK: - Public
extension ProductCell {
    /// Update UI 메소드
    func updateUI(
        type: ProductCellType,
        title: String,
        freshness: Int?,
        descriptions: [String]?,
        subdescriptions: [String]?,
        count: Int?,
        image: UIImage?,
    ) {
        cellType = type
        productTitleLabel.text = title
        productImageView.image = image
        productImageView.backgroundColor = image == nil ? .accent : .clear
        
        updateDescriptionStack(
            stackView: productDescriptionStack,
            freshness: freshness,
            texts: descriptions,
        )
        
        if cellType != .registType {
            productCountLabel.text = count.map { String($0) } ?? "0"
        }
        
        if cellType == .detailType {
            updateDescriptionStack(
                stackView: productSubDescriptionStack,
                freshness: nil,
                texts: subdescriptions,
            )
        }
    }
}

// MARK: - Update
private extension ProductCell {
    
    /// 설명 스택에 삽입될 텍스트 라벨 제작 메소드
    private func updateDescriptionStack(
        stackView: UIStackView,
        freshness: Int?,
        texts: [String]?
    ) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        var labels: [UILabel] = []
        
        /// 유통기한 텍스트 생성
        if let freshness {
            let freshnessLabel = StyledLabel(
                config: .body12.updatingColor(color: .primaryRed)
            ).then {
                $0.text = freshness > 0 ? "\(freshness)일 남음" : "소비기한 만료"
                $0.numberOfLines = 1
            }
            labels.append(freshnessLabel)
        }
        
        /// 설명 라벨 생성
        texts?.forEach { text in
            let label = StyledLabel(config: .body12.updatingColor(color: .gray300)).then {
                $0.text = text
                $0.numberOfLines = 1
            }
            labels.append(label)
        }
        
        /// 스택뷰에 삽입
        labels.enumerated().forEach { index, label in
            stackView.addArrangedSubview(label)
            
            // dot 라벨 추가
            if index < labels.count - 1 {
                let dotLabel = StyledLabel(config: .body12.updatingColor(color: .gray300)).then {
                    $0.text = "·"
                    $0.numberOfLines = 1
                }
                stackView.addArrangedSubview(dotLabel)
            }
        }
    }
}


// MARK: - Layout
private extension ProductCell {
    
    func configureUI() {
        backgroundColor = .clear

        var backgroundConfig = UIBackgroundConfiguration.clear()
        backgroundConfig.backgroundColor = .white
        backgroundConfig.cornerRadius = 8
        self.backgroundConfiguration = backgroundConfig

        directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 8,
            leading: 16,
            bottom: 8,
            trailing: 16
        )

        contentView.addSubview(productMainStack)
        contentView.addSubview(productCountView)
        
        productMainStack.addArrangedSubview(productImageView)
        productMainStack.addArrangedSubview(productInfoStack)
        
        productInfoStack.addArrangedSubview(productTitleLabel)
        productInfoStack.addArrangedSubview(productDescriptionStack)
        productInfoStack.addArrangedSubview(productSubDescriptionStack)
        
        productCountView.addSubview(productCountLabel)
        productCountView.addSubview(countUnitLabel)
        
        productMainStack.snp.makeConstraints {
            $0.top.equalTo(contentView).offset(12)
            $0.bottom.equalTo(contentView).inset(12)
            $0.leading.equalTo(contentView).offset(16)
            $0.trailing.lessThanOrEqualTo(productCountView.snp.leading).offset(-12)
            $0.height.equalTo(64)
        }
        
        productCountView.snp.makeConstraints {
            $0.centerY.equalTo(contentView)
            $0.trailing.equalTo(contentView).inset(16)
        }
        
        productInfoStack.snp.makeConstraints {
            $0.width.greaterThanOrEqualTo(80)
        }
        
        productImageView.snp.makeConstraints {
            $0.size.equalTo(64)
        }
        
        productCountLabel.snp.makeConstraints {
            $0.trailing.equalTo(countUnitLabel.snp.leading).offset(-2)
            $0.lastBaseline.equalTo(countUnitLabel.snp.lastBaseline)
        }
        
        countUnitLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
        }
    }
}
