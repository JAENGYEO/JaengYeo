//
//  RegisterDetailView.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/12/26.
//

import UIKit
import SnapKit
import Then

final class RegisterDetailView: UIView {

    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
    }
    private let contentView = UIView()
    private let stackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 32
    }

    // MARK: 기본 필드
    let nameField = UITextField().then {
        $0.font = LabelConfiguration.titleSemi16.font
        $0.textColor = .gray800
        $0.attributedPlaceholder = NSAttributedString(
            string: "상품명을 입력해주세요.",
            attributes: [.foregroundColor: UIColor.gray300, .font: LabelConfiguration.body14.font]
        )
    }

    let quantityField = UITextField().then {
        $0.font = LabelConfiguration.titleSemi16.font
        $0.textColor = .gray800
        $0.keyboardType = .numberPad
        $0.attributedPlaceholder = NSAttributedString(
            string: "수량을 입력해주세요.",
            attributes: [.foregroundColor: UIColor.gray300, .font: LabelConfiguration.body14.font]
        )
    }

    let purchaseDateField = UITextField().then {
        $0.font = LabelConfiguration.titleSemi16.font
        $0.textColor = .gray800
        $0.attributedPlaceholder = NSAttributedString(
            string: "구매 날짜를 입력해주세요.",
            attributes: [.foregroundColor: UIColor.gray300, .font: LabelConfiguration.body14.font]
        )
    }

    let foodButton = UIButton().then {
        $0.setTitle("식재료", for: .normal)
        $0.layer.cornerRadius = 12
        $0.layer.borderWidth = 1
    }

    let householdButton = UIButton().then {
        $0.setTitle("생활용품", for: .normal)
        $0.layer.cornerRadius = 12
        $0.layer.borderWidth = 1
    }

    let locationField = UITextField().then {
        $0.font = LabelConfiguration.titleSemi16.font
        $0.textColor = .gray800
        $0.attributedPlaceholder = NSAttributedString(
            string: "보관 위치를 입력해주세요.",
            attributes: [.foregroundColor: UIColor.gray300, .font: LabelConfiguration.body14.font]
        )
    }

    // MARK: 추가버튼, 추가 필드
    let addInfoButton = UIButton().then {
        let attributed = NSMutableAttributedString(
            string: "정보 추가하기",
            attributes: [
                .foregroundColor: UIColor(named: "Primary300") ?? .systemBlue,
                .font: LabelConfiguration.body12.font,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ]
        )
        $0.setAttributedTitle(attributed, for: .normal)
    }

    let subCategoryField = UITextField().then {
        $0.font = LabelConfiguration.titleSemi16.font
        $0.textColor = .gray800
        $0.attributedPlaceholder = NSAttributedString(
            string: "제품의 종류를 입력해주세요.",
            attributes: [.foregroundColor: UIColor.gray300, .font: LabelConfiguration.body14.font]
        )
    }

    let photoButton = UIButton().then {
        $0.setImage(UIImage(systemName: "photo"), for: .normal)
        $0.tintColor = UIColor(named: "Primary300")
        $0.layer.cornerRadius = 12
        $0.layer.borderWidth = 2
        $0.layer.borderColor = UIColor(named: "Primary100")?.cgColor
    }

    let expiryDateField = UITextField().then {
        $0.font = LabelConfiguration.titleSemi16.font
        $0.textColor = .gray800
        $0.attributedPlaceholder = NSAttributedString(
            string: "유통기한을 입력해주세요.",
            attributes: [.foregroundColor: UIColor.gray300, .font: LabelConfiguration.body14.font]
        )
    }

    let cautionField = UITextField().then {
        $0.font = LabelConfiguration.titleSemi16.font
        $0.textColor = .gray800
        $0.attributedPlaceholder = NSAttributedString(
            string: "유의사항 / 취급 주의사항을 입력해주세요.",
            attributes: [.foregroundColor: UIColor.gray300, .font: LabelConfiguration.body14.font]
        )
    }

    let brandField = UITextField().then {
        $0.font = LabelConfiguration.titleSemi16.font
        $0.textColor = .gray800
        $0.attributedPlaceholder = NSAttributedString(
            string: "구매하신 제품의 브랜드를 입력해주세요.",
            attributes: [.foregroundColor: UIColor.gray300, .font: LabelConfiguration.body14.font]
        )
    }

    let stockAlertLabel = UILabel().then {
        $0.text = "0"
        $0.font = LabelConfiguration.body14.font
        $0.textColor = .gray800
        $0.textAlignment = .center
    }

    let stockMinusButton = UIButton().then {
        $0.setImage(UIImage(systemName: "minus"), for: .normal)
        $0.tintColor = .gray300
    }

    let stockPlusButton = UIButton().then {
        $0.setImage(UIImage(systemName: "plus"), for: .normal)
        $0.tintColor = .gray300
    }

    let memoField = UITextField().then {
        $0.font = LabelConfiguration.titleSemi16.font
        $0.textColor = .gray800
        $0.attributedPlaceholder = NSAttributedString(
            string: "자유롭게 메모해주세요.",
            attributes: [.foregroundColor: UIColor.gray300, .font: LabelConfiguration.body14.font]
        )
    }

    // MARK: 추가 필드 그룹뷰 (show/hide 단위)
    private(set) lazy var subCategoryGroupView = makeFieldGroup(title: "소분류", field: subCategoryField)
    private(set) lazy var photoGroupView = makePhotoGroup()
    private(set) lazy var expiryDateGroupView = makeFieldGroup(title: "유통기한", field: expiryDateField)
    private(set) lazy var cautionGroupView = makeFieldGroup(title: "유의사항 / 취급 주의사항", field: cautionField)
    private(set) lazy var brandGroupView = makeFieldGroup(title: "브랜드", field: brandField)
    private(set) lazy var stockAlertGroupView = makeStockAlertGroup()
    private(set) lazy var memoGroupView = makeFieldGroup(title: "메모", field: memoField)

    // MARK: 저장 버튼
    private let bottomView = UIView().then {
        $0.backgroundColor = .white
    }
    let confirmButton = UIButton().then {
        $0.setTitle("완료", for: .normal)
        $0.titleLabel?.font = LabelConfiguration.bodyMedium14.font
        $0.backgroundColor = .accent
        $0.layer.cornerRadius = 12
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension RegisterDetailView {
    private func setLayout() {
        backgroundColor = .white

        let nameGroup = makeFieldGroup(title: "상품명*", field: nameField)
        let quantityGroup = makeFieldGroup(title: "수량*", field: quantityField)
        let purchaseDateGroup = makeFieldGroup(title: "구매날짜*", field: purchaseDateField)
        let categoryGroup = makeCategoryGroup()
        let locationGroup = makeFieldGroup(title: "중분류(위치)*", field: locationField)

        [nameGroup, quantityGroup, purchaseDateGroup, categoryGroup, locationGroup].forEach {
            stackView.addArrangedSubview($0)
        }

        [subCategoryGroupView, photoGroupView, expiryDateGroupView,
         cautionGroupView, brandGroupView, stockAlertGroupView, memoGroupView].forEach {
            $0.isHidden = true
            stackView.addArrangedSubview($0)
        }

        contentView.addSubview(stackView)
        contentView.addSubview(addInfoButton)
        scrollView.addSubview(contentView)

        [scrollView, bottomView].forEach { addSubview($0) }
        bottomView.addSubview(confirmButton)

        bottomView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.top.equalTo(confirmButton.snp.top).offset(-8)
        }
        confirmButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(safeAreaLayoutGuide).offset(-8)
            $0.height.equalTo(48)
        }
        scrollView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(bottomView.snp.top)
        }
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }
        stackView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        addInfoButton.snp.makeConstraints {
            $0.top.equalTo(stackView.snp.bottom).offset(16)
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-16)
        }
    }
}

// MARK: 그룹 생성
extension RegisterDetailView {
    private func makeFieldGroup(title: String, field: UITextField) -> UIView {
        let container = UIView()
        let titleLabel = UILabel().then {
            $0.text = title
            $0.font = LabelConfiguration.bodyMedium14.font
            $0.textColor = .gray600
        }
        let separator = UIView().then {
            $0.backgroundColor = .gray100
        }
        [titleLabel, field, separator].forEach { container.addSubview($0) }

        titleLabel.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(32)
        }
        field.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom)
            $0.leading.trailing.equalToSuperview().inset(4)
            $0.height.equalTo(36)
        }
        separator.snp.makeConstraints {
            $0.top.equalTo(field.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(1)
        }
        return container
    }

    private func makeCategoryGroup() -> UIView {
        let container = UIView()
        let titleLabel = UILabel().then {
            $0.text = "대분류*"
            $0.font = LabelConfiguration.bodyMedium14.font
            $0.textColor = .gray600
        }
        let buttonStack = UIStackView().then {
            $0.axis = .horizontal
            $0.distribution = .fillEqually
            $0.spacing = 17
        }
        [foodButton, householdButton].forEach { buttonStack.addArrangedSubview($0) }
        [titleLabel, buttonStack].forEach { container.addSubview($0) }

        titleLabel.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(32)
        }
        buttonStack.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(44)
        }
        return container
    }

    private func makePhotoGroup() -> UIView {
        let container = UIView()
        let titleLabel = UILabel().then {
            $0.text = "사진"
            $0.font = LabelConfiguration.bodyMedium14.font
            $0.textColor = .gray600
        }
        [titleLabel, photoButton].forEach { container.addSubview($0) }

        titleLabel.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(32)
        }
        photoButton.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.leading.equalToSuperview()
            $0.size.equalTo(48)
            $0.bottom.equalToSuperview()
        }
        return container
    }

    private func makeStockAlertGroup() -> UIView {
        let container = UIView()
        let titleLabel = UILabel().then {
            $0.text = "알림 재고 수량"
            $0.font = LabelConfiguration.titleSemi16.font
            $0.textColor = .gray800
        }
        let stepperContainer = UIView().then {
            $0.layer.borderWidth = 1
            $0.layer.borderColor = UIColor.gray100.cgColor
            $0.layer.cornerRadius = 8
        }
        [stockMinusButton, stockAlertLabel, stockPlusButton].forEach { stepperContainer.addSubview($0) }
        [titleLabel, stepperContainer].forEach { container.addSubview($0) }

        stepperContainer.snp.makeConstraints {
            $0.leading.equalTo(titleLabel.snp.trailing).offset(24)
            $0.centerY.equalTo(titleLabel)
            $0.height.equalTo(36)
        }
        stockMinusButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(8)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(16)
        }
        stockAlertLabel.snp.makeConstraints {
            $0.leading.equalTo(stockMinusButton.snp.trailing).offset(20)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(20)
        }
        stockPlusButton.snp.makeConstraints {
            $0.leading.equalTo(stockAlertLabel.snp.trailing).offset(20)
            $0.trailing.equalToSuperview().offset(-8)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(16)
        }
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.centerY.equalTo(stepperContainer)
            $0.top.bottom.equalToSuperview()
        }
        return container
    }
}

// MARK: 대분류 버튼 상태 업데이트
extension RegisterDetailView {
    enum CategoryType { case food, household }

    func updateCategoryButtons(selected: CategoryType?) {
        let selectedColor = UIColor.accent
        let deselectedColor = UIColor.gray300

        foodButton.layer.borderColor = (selected == .food ? selectedColor : deselectedColor).cgColor
        foodButton.layer.borderWidth = selected == .food ? 2 : 1
        foodButton.setTitleColor(selected == .food ? selectedColor : .gray500, for: .normal)
        foodButton.titleLabel?.font = selected == .food ? LabelConfiguration.bodyMedium14.font : LabelConfiguration.body14.font

        householdButton.layer.borderColor = (selected == .household ? selectedColor : deselectedColor).cgColor
        householdButton.layer.borderWidth = selected == .household ? 2 : 1
        householdButton.setTitleColor(selected == .household ? selectedColor : .gray500, for: .normal)
        householdButton.titleLabel?.font = selected == .household ? LabelConfiguration.bodyMedium14.font : LabelConfiguration.body14.font
    }
}
