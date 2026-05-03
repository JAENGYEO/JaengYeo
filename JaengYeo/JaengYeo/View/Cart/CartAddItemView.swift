//
//  CartAddItemView.swift
//  JaengYeo
//
//  Created by Hanjuheon on 5/3/26.
//

import SnapKit
import Then
import UIKit

final class CartAddItemView: UIView {

    //MARK: - Components
    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
    }

    private let contentView = UIView()

    private let stackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 32
    }

    let nameField = UITextField().then {
        $0.font = LabelConfiguration.titleSemi16.font
        $0.textColor = .gray800
        $0.attributedPlaceholder = NSAttributedString(
            string: "상품명을 입력해주세요. (최대 20자)",
            attributes: [
                .foregroundColor: UIColor.gray300,
                .font: LabelConfiguration.body14.font
            ]
        )
    }

    let quantityField = UITextField().then {
        $0.font = LabelConfiguration.titleSemi16.font
        $0.textColor = .gray800
        $0.keyboardType = .numberPad
        $0.attributedPlaceholder = NSAttributedString(
            string: "수량을 입력해주세요. (최대 999)",
            attributes: [
                .foregroundColor: UIColor.gray300,
                .font: LabelConfiguration.body14.font
            ]
        )
    }

    let foodButton = UIButton().then {
        $0.setTitle(MainCategory.foodstuff.rawValue, for: .normal)
        $0.layer.cornerRadius = 12
        $0.layer.borderWidth = 1
    }

    let householdButton = UIButton().then {
        $0.setTitle(MainCategory.household.rawValue, for: .normal)
        $0.layer.cornerRadius = 12
        $0.layer.borderWidth = 1
    }

    private let bottomView = UIView().then {
        $0.backgroundColor = .white
    }

    let deleteButton = StyledButton(
        title: "삭제",
        titleConfiguration: .redTitle,
        appearanceConfiguration: .redAppearance
    )

    let saveButton = StyledButton(
        title: "저장",
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

//MARK: - Public
extension CartAddItemView {
    /// 화면 모드에 맞게 하단 버튼 업데이트
    func updateMode(isEdit: Bool) {
        deleteButton.isHidden = !isEdit
        saveButton.updateTitle(isEdit ? "수정" : "저장")
        configureBottomButtonConstraints(isEdit: isEdit)
    }

    /// 대분류 버튼 상태 업데이트
    func updateCategoryButtons(selected: MainCategory?) {
        updateButton(foodButton, isSelected: selected == .foodstuff)
        updateButton(householdButton, isSelected: selected == .household)
    }
}

//MARK: - Configure UI
extension CartAddItemView {
    func configureUI() {
        backgroundColor = .white

        let nameGroup = makeFieldGroup(title: "상품명*", field: nameField)
        let quantityGroup = makeFieldGroup(title: "수량*", field: quantityField)
        let categoryGroup = makeCategoryGroup()

        [nameGroup, quantityGroup, categoryGroup].forEach {
            stackView.addArrangedSubview($0)
        }

        contentView.addSubview(stackView)
        scrollView.addSubview(contentView)

        addSubview(scrollView)
        addSubview(bottomView)
        bottomView.addSubview(deleteButton)
        bottomView.addSubview(saveButton)

        bottomView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.top.equalTo(saveButton.snp.top).offset(-8)
        }

        keyboardLayoutGuide.usesBottomSafeArea = true
        updateMode(isEdit: false)

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
            $0.bottom.lessThanOrEqualToSuperview().offset(-16)
        }
    }

    func configureBottomButtonConstraints(isEdit: Bool) {
        if isEdit {
            deleteButton.snp.remakeConstraints {
                $0.leading.equalToSuperview().offset(24)
                $0.bottom.equalTo(keyboardLayoutGuide.snp.top).offset(-8)
                $0.width.equalTo(89)
                $0.height.equalTo(48)
            }

            saveButton.snp.remakeConstraints {
                $0.leading.equalTo(deleteButton.snp.trailing).offset(16)
                $0.trailing.equalToSuperview().inset(16)
                $0.centerY.equalTo(deleteButton)
                $0.height.equalTo(48)
            }
            return
        }

        saveButton.snp.remakeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(keyboardLayoutGuide.snp.top).offset(-8)
            $0.height.equalTo(48)
        }
    }
}

//MARK: - Components
private extension CartAddItemView {
    func makeFieldGroup(title: String, field: UITextField) -> UIView {
        let container = UIView()

        let titleLabel = UILabel().then {
            $0.text = title
            $0.font = LabelConfiguration.bodyMedium14.font
            $0.textColor = .gray600
        }

        let separator = UIView().then {
            $0.backgroundColor = .gray100
        }

        [titleLabel, field, separator].forEach {
            container.addSubview($0)
        }

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

    func makeCategoryGroup() -> UIView {
        let container = UIView()

        let titleLabel = UILabel().then {
            $0.text = "대분류*"
            $0.font = LabelConfiguration.bodyMedium14.font
            $0.textColor = .gray600
        }

        let buttonStackView = UIStackView().then {
            $0.axis = .horizontal
            $0.distribution = .fillEqually
            $0.spacing = 17
        }

        [foodButton, householdButton].forEach {
            buttonStackView.addArrangedSubview($0)
        }

        [titleLabel, buttonStackView].forEach {
            container.addSubview($0)
        }

        titleLabel.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(32)
        }

        buttonStackView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(44)
        }

        return container
    }

    func updateButton(_ button: UIButton, isSelected: Bool) {
        button.layer.borderColor = (isSelected ? UIColor.accent : UIColor.gray300).cgColor
        button.layer.borderWidth = isSelected ? 2 : 1
        button.setTitleColor(isSelected ? .accent : .gray500, for: .normal)
        button.titleLabel?.font = isSelected
            ? LabelConfiguration.bodyMedium14.font
            : LabelConfiguration.body14.font
    }
}

#Preview {
    CartAddItemView()
}
