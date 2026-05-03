//
//  CartProductCell.swift
//  JaengYeo
//
//  Created by Hanjuheon on 5/1/26.
//

import UIKit
import SnapKit
import Then
import RxCocoa
import RxRelay
import RxSwift

final class CartProductCell: UICollectionViewListCell {

    //MARK: - Properties
    private var disposeBag = DisposeBag()
    private let checkButtonTapRelay = PublishRelay<Void>()

    //MARK: - Components
    private let checkButton = UIButton(type: .custom).then {
        $0.imageView?.contentMode = .scaleAspectFit
    }

    private let contentStack = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 8
        $0.alignment = .center
        $0.distribution = .fill
    }

    private let productInfoStack = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 4
        $0.alignment = .leading
        $0.distribution = .fill
    }

    private let titleLabel = StyledLabel(config: .bodyMedium14).then {
        $0.numberOfLines = 1
        $0.lineBreakMode = .byTruncatingTail
        $0.updateColor(.gray800)
    }

    private let categoryLabel = StyledLabel(config: .body12.updatingColor(color: .gray300)).then {
        $0.numberOfLines = 1
        $0.lineBreakMode = .byTruncatingTail
    }

    private let upDownCountView = ProductUpDownCountView().then {
        $0.backgroundColor = .clear
    }

    //MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
        bind()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        titleLabel.text = nil
        categoryLabel.text = nil
        checkButton.isHidden = false
        updateCheckButton(isSelected: false)
        bind()
    }
}

//MARK: - Public
extension CartProductCell {
    /// 체크 버튼 선택 이벤트
    var checkButtonTap: Observable<Void> {
        checkButtonTapRelay.asObservable()
    }

    /// 수량 추가 버튼 선택 이벤트
    var addButtonTap: Observable<Void> {
        upDownCountView.addButtonTap
    }

    /// 수량 차감 버튼 선택 이벤트
    var deleteButtonTap: Observable<Void> {
        upDownCountView.deleteButtonTap
    }

    /// 셀 UI 업데이트
    func updateUI(
        title: String,
        category: String,
        count: Int,
        isSelected: Bool,
        showsCheckBox: Bool
    ) {
        titleLabel.text = title
        categoryLabel.text = category
        upDownCountView.updateUI(count: count)
        checkButton.isHidden = !showsCheckBox
        updateCheckButton(isSelected: isSelected)
    }

    /// 체크 버튼 선택 바인딩
    func bindCheckButtonTap(onNext: @escaping () -> Void) {
        checkButtonTap
            .bind(onNext: onNext)
            .disposed(by: disposeBag)
    }

    /// 수량 추가 버튼 선택 바인딩
    func bindAddButtonTap(onNext: @escaping () -> Void) {
        addButtonTap
            .bind(onNext: onNext)
            .disposed(by: disposeBag)
    }

    /// 수량 차감 버튼 선택 바인딩
    func bindDeleteButtonTap(onNext: @escaping () -> Void) {
        deleteButtonTap
            .bind(onNext: onNext)
            .disposed(by: disposeBag)
    }
}

//MARK: - Binding
private extension CartProductCell {
    /// 버튼 이벤트 바인딩
    func bind() {
        checkButton.rx.tap
            .bind(to: checkButtonTapRelay)
            .disposed(by: disposeBag)
    }
}

//MARK: - Update
private extension CartProductCell {
    /// 체크 버튼 이미지 갱신
    func updateCheckButton(isSelected: Bool) {
        checkButton.setImage(
            UIImage(named: isSelected ? "onIcon" : "offIcon"),
            for: .normal
        )
    }

}

//MARK: - Configure UI
private extension CartProductCell {
    /// UI 설정
    func configureUI() {
        configureStyle()
        configureHierarchy()
        configureLayout()
    }

    /// 스타일 설정
    func configureStyle() {
        backgroundColor = .clear
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 8
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.gray100.cgColor
        contentView.clipsToBounds = true
    }

    /// 계층 설정
    func configureHierarchy() {
        contentView.addSubview(contentStack)
        contentView.addSubview(upDownCountView)

        contentStack.addArrangedSubview(checkButton)
        contentStack.addArrangedSubview(productInfoStack)
        productInfoStack.addArrangedSubview(titleLabel)
        productInfoStack.addArrangedSubview(categoryLabel)
    }

    /// 레이아웃 설정
    func configureLayout() {
        checkButton.snp.makeConstraints {
            $0.size.equalTo(24)
        }

        contentStack.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.trailing.lessThanOrEqualTo(upDownCountView.snp.leading).offset(-8)
        }

        upDownCountView.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(6)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(100)
            $0.height.equalTo(44)
        }
    }
}
