//
//  Untitled.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/8/26.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

//MARK: - Enum
/// 상품 셀 디자인 타입
enum ProductCellType {
    /// 기본 디자인
    case defaultType
    /// 상품 추가 정보 표기 디자인
    case detailType
    /// 등록 디자인
    case registType
    /// 홈디자인
    case homeType
    /// 미분류 상품 디자인
    case unclassifiedType
}

/// 공용 상품 셀
final class ProductCell: UICollectionViewListCell{

    static let id = "ProductCell"

    // MARK: - Properties
    private var disposeBag = DisposeBag()
    private var mainStackTrailingToCountConstraint: Constraint?
    private var mainStackTrailingToUpDownConstraint: Constraint?

    private var cellType: ProductCellType = .defaultType {
        didSet {
            switch cellType {
            case .defaultType:
                productSubDescriptionStack.isHidden = true
                productCountView.isHidden = true
                upDownCountView.isHidden = false
                
            case .detailType:
                productSubDescriptionStack.isHidden = false
                productCountView.isHidden = false
                upDownCountView.isHidden = true
                
            case .registType:
                productSubDescriptionStack.isHidden = false
                productCountView.isHidden = true
                upDownCountView.isHidden = true
            
            case .homeType:
                productSubDescriptionStack.isHidden = false
                productCountView.isHidden = true
                upDownCountView.isHidden = false
                var config = backgroundConfiguration ?? UIBackgroundConfiguration.clear()
                config.strokeColor = UIColor.gray100
                config.strokeWidth = 1
                backgroundConfiguration = config
            
            case .unclassifiedType:
                productSubDescriptionStack.isHidden = true
                productCountView.isHidden = true
                upDownCountView.isHidden = true
            }

            updateMainStackTrailingConstraint()
        }
    }
    
    // MARK: - Components
    /// 아이템 이미지 뷰
    private let productImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 8
        $0.backgroundColor = .clear
    }
    
    /// 아이템 타이틀
    private let productTitleLabel = StyledLabel(config: .bodyMedium14).then {
        $0.text = ""
        $0.numberOfLines = 1
        $0.lineBreakMode = .byTruncatingTail
    }
    
    /// 아이템 카운트
    private let productCountLabel = StyledLabel(config: .titleSemi18).then {
        $0.text = ""
        $0.numberOfLines = 1
    }
    
    /// 카운트 단위
    private let countUnitLabel = StyledLabel(config: .body12.updatingColor(color: .gray300)).then {
        $0.text = "개"
        $0.numberOfLines = 1
    }

    private let upDownCountView = ProductUpDownCountView().then {
        $0.isHidden = true
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag = DisposeBag()
        cellType = .defaultType
        accessories = []
        productTitleLabel.text = nil
        productTitleLabel.numberOfLines = 1
        productTitleLabel.lineBreakMode = .byTruncatingTail
        productCountLabel.text = "0"
        productImageView.image = UIImage(named: "imageSelectIcon")
        productImageView.backgroundColor = .clear
        
        var config = backgroundConfiguration ?? UIBackgroundConfiguration.clear()
        config.strokeWidth = 0
        config.strokeColor = .clear
        backgroundConfiguration = config
        
        updateDescriptionStack(
            stackView: productDescriptionStack,
            freshness: nil,
            texts: nil
        )
        
        updateDescriptionStack(
            stackView: productSubDescriptionStack,
            freshness: nil,
            texts: nil
        )
        
        updateMainStackTrailingConstraint()
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
        highlightFirst: Bool = false
    ) {
        cellType = type
        productTitleLabel.text = title
        productTitleLabel.numberOfLines = 1
        productTitleLabel.lineBreakMode = .byTruncatingTail
        productImageView.image = image ?? UIImage(named: "imageSelectIcon")
        productImageView.backgroundColor = .clear

        updateDescriptionStack(
            stackView: productDescriptionStack,
            freshness: freshness,
            texts: descriptions,
            highlightFirst: highlightFirst
        )
        
        if usesUpDownCountView {
            productCountView.isHidden = true
            upDownCountView.isHidden = false
            upDownCountView.updateUI(count: count)
        } else {
            switch cellType {
            case .detailType:
                productCountLabel.text = count.map { String($0) } ?? "0"
                productCountView.isHidden = false
                upDownCountView.isHidden = true

            case .registType, .unclassifiedType:
                productCountView.isHidden = true
                upDownCountView.isHidden = true

            case .defaultType, .homeType:
                break
            }
        }
        
        if cellType == .detailType || cellType == .registType || cellType == .homeType {
            updateDescriptionStack(
                stackView: productSubDescriptionStack,
                freshness: nil,
                texts: subdescriptions,
            )
        }

        updateMainStackTrailingConstraint()

    }

    /// 수량 추가 버튼 선택 바인딩
    func bindAddButtonTap(onNext: @escaping () -> Void) {
        upDownCountView.addButtonTap
            .bind(onNext: onNext)
            .disposed(by: disposeBag)
    }

    /// 수량 차감 버튼 선택 바인딩
    func bindDeleteButtonTap(onNext: @escaping () -> Void) {
        upDownCountView.deleteButtonTap
            .bind(onNext: onNext)
            .disposed(by: disposeBag)
    }

    /// 수량 증감 뷰 사용 여부
    private var usesUpDownCountView: Bool {
        switch cellType {
        case .defaultType, .homeType:
            return true
        case .detailType, .registType, .unclassifiedType:
            return false
        }
    }
}

// MARK: - Update
private extension ProductCell {
    /// 우측 컴포넌트에 맞게 메인 스택 최대 너비 갱신
    func updateMainStackTrailingConstraint() {
        if usesUpDownCountView {
            mainStackTrailingToCountConstraint?.deactivate()
            mainStackTrailingToUpDownConstraint?.activate()
        } else {
            mainStackTrailingToUpDownConstraint?.deactivate()
            mainStackTrailingToCountConstraint?.activate()
        }
    }
    
    /// 설명 스택에 삽입될 텍스트 라벨 제작 메소드
    private func updateDescriptionStack(
        stackView: UIStackView,
        freshness: Int?,
        texts: [String]?,
        highlightFirst: Bool = false
    ) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        var labels: [UILabel] = []
        
        /// 유통기한 텍스트 생성
        if let freshness {
            let freshnessLabel = StyledLabel(
                config: .body12.updatingColor(color: .primaryRed)
            ).then {
                if freshness > 0 {
                    $0.text =  "\(freshness)일 남음"
                } else if freshness == 0 {
                    $0.text =  "오늘 만료"
                } else {
                    $0.text =  "유통기한 만료"
                }
                $0.numberOfLines = 1
            }
            labels.append(freshnessLabel)
        }
        
        /// 설명 라벨 생성
        texts?.enumerated().forEach { index ,text in
            let color: UIColor = (highlightFirst && index == 0) ? .primaryRed : .gray300
            let label = StyledLabel(config: .body12.updatingColor(color: color)).then {
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

//        directionalLayoutMargins = NSDirectionalEdgeInsets(
//            top: 8,
//            leading: 16,
//            bottom: 8,
//            trailing: 16
//        )

        contentView.addSubview(productMainStack)
        contentView.addSubview(productCountView)
        contentView.addSubview(upDownCountView)
        
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
            $0.height.equalTo(64)
            mainStackTrailingToCountConstraint = $0.trailing
                .lessThanOrEqualTo(productCountView.snp.leading)
                .offset(-12)
                .constraint
            mainStackTrailingToUpDownConstraint = $0.trailing
                .lessThanOrEqualTo(upDownCountView.snp.leading)
                .offset(-12)
                .constraint
        }
        
        productCountView.snp.makeConstraints {
            $0.centerY.equalTo(contentView)
            $0.trailing.equalTo(contentView).inset(16)
            $0.top.bottom.equalTo(productMainStack)
        }

        upDownCountView.snp.makeConstraints {
            $0.centerY.equalTo(contentView)
            $0.trailing.equalTo(contentView).inset(16)
            $0.width.equalTo(100)
            $0.height.equalTo(44)
        }

        productInfoStack.snp.makeConstraints {
            $0.width.greaterThanOrEqualTo(80)
        }
        
        productImageView.snp.makeConstraints {
            $0.size.equalTo(64)
        }
        
        productCountLabel.snp.makeConstraints {
            $0.trailing.equalTo(countUnitLabel.snp.leading).offset(-2)
            $0.leading.equalToSuperview()
            $0.lastBaseline.equalTo(countUnitLabel.snp.lastBaseline)
        }
        
        countUnitLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
        }
        
        updateMainStackTrailingConstraint()
    }
}
