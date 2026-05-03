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
    /// 검색 결과 디자인
    case searchType
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
            
            case .homeType, .searchType:
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
    private let productTitleLabel = UILabel().then {
        $0.font = LabelConfiguration.bodyMedium14.font
        $0.textColor = .gray800
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
        highlightFirst: Bool = false,
        keyword: String? = nil
    ) {
        cellType = type
        productTitleLabel.numberOfLines = 1
        productTitleLabel.lineBreakMode = .byTruncatingTail
        productImageView.image = image ?? UIImage(named: "imageSelectIcon")
        productImageView.backgroundColor = .clear

        if let keyword, !keyword.isEmpty,
           title.lowercased().contains(keyword.lowercased()) {
            productTitleLabel.attributedText = makeHighlightedAttributedString(
                title,
                keyword: keyword,
                baseFont: LabelConfiguration.bodyMedium14.font,
                baseColor: .gray800
            )
        } else {
            productTitleLabel.attributedText = NSAttributedString(
                string: title,
                attributes: [
                    .font: LabelConfiguration.bodyMedium14.font,
                    .foregroundColor: UIColor.gray800
                ]
            )
        }

        if type == .searchType {
            let freshnessText: String? = freshness.map { f in
                if f > 0 { return "\(f)일 남음" }
                else if f == 0 { return "오늘 만료" }
                else { return "유통기한 만료" }
            }
            let resolvedDescriptions = [freshnessText].compactMap { $0 } + (descriptions ?? [])
            updateDescriptionStack(
                stackView: productDescriptionStack,
                freshness: nil,
                texts: resolvedDescriptions,
                highlightFirst: highlightFirst,
                keyword: keyword
            )
        } else {
            updateDescriptionStack(
                stackView: productDescriptionStack,
                freshness: freshness,
                texts: descriptions,
                highlightFirst: highlightFirst,
                keyword: keyword
            )
        }

        if usesUpDownCountView {
            productCountView.isHidden = true
            upDownCountView.isHidden = false
            upDownCountView.updateUI(count: count)
        } else {
            switch cellType {
            case .detailType, .searchType:
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
        
        if cellType == .detailType || cellType == .registType || cellType == .homeType || cellType == .searchType {
            updateDescriptionStack(
                stackView: productSubDescriptionStack,
                freshness: nil,
                texts: subdescriptions
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
        case .detailType, .registType, .unclassifiedType, .searchType:
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
    private func makeHighlightedAttributedString(
        _ text: String,
        keyword: String,
        baseFont: UIFont,
        baseColor: UIColor
    ) -> NSAttributedString {
        let attributed = NSMutableAttributedString(
            string: text,
            attributes: [
                .font: baseFont,
                .foregroundColor: baseColor
            ]
        )
        let lowercasedText = text.lowercased()
        let lowercasedKeyword = keyword.lowercased()
        var searchRange = lowercasedText.startIndex..<lowercasedText.endIndex

        while let range = lowercasedText.range(of: lowercasedKeyword, range: searchRange) {
            attributed.addAttribute(
                .foregroundColor,
                value: UIColor.primaryRed,
                range: NSRange(range, in: text)
            )
            searchRange = range.upperBound..<lowercasedText.endIndex
        }

        return attributed
    }

    private func updateDescriptionStack(
        stackView: UIStackView,
        freshness: Int?,
        texts: [String]?,
        highlightFirst: Bool = false,
        keyword: String? = nil
    ) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        var labels: [UILabel] = []
        
        /// 유통기한 텍스트 생성
        if let freshness {
            let freshnessText: String
            if freshness > 0 { freshnessText = "\(freshness)일 남음" }
            else if freshness == 0 { freshnessText = "오늘 만료" }
            else { freshnessText = "유통기한 만료" }

            let freshnessLabel = UILabel().then {
                $0.font = LabelConfiguration.body12.font
                $0.textColor = .primaryRed
                $0.text = freshnessText
                $0.numberOfLines = 1
            }
            labels.append(freshnessLabel)
        }

        /// 설명 라벨 생성
        texts?.enumerated().forEach { index, text in
            let baseColor: UIColor = (highlightFirst && index == 0) ? .primaryRed : .gray300
            let label = UILabel().then {
                $0.font = LabelConfiguration.body12.font
                $0.textColor = baseColor
                $0.numberOfLines = 1
                if let keyword, !keyword.isEmpty,
                   text.lowercased().contains(keyword.lowercased()) {
                    $0.attributedText = makeHighlightedAttributedString(
                        text,
                        keyword: keyword,
                        baseFont: LabelConfiguration.body12.font,
                        baseColor: baseColor
                    )
                } else {
                    $0.text = text
                }
            }
            labels.append(label)
        }

        /// 스택뷰에 삽입
        labels.enumerated().forEach { index, label in
            stackView.addArrangedSubview(label)

            // dot 라벨 추가
            if index < labels.count - 1 {
                let dotLabel = UILabel().then {
                    $0.font = LabelConfiguration.body12.font
                    $0.textColor = .gray300
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
