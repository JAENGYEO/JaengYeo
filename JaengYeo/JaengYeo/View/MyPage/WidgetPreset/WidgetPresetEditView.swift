//
//  WidgetPresetEditView.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/30/26.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

enum WidgetPresetEditSection: Int, CaseIterable {
    case main
}

final class WidgetPresetEditView: UIView {

    private let nameLabel = UILabel().then {
        let attr = NSMutableAttributedString(
            string: "프리셋명",
            attributes: [
                .font: LabelConfiguration.bodyMedium14.font,
                .foregroundColor: UIColor.gray600
            ]
        )
        attr.append(NSAttributedString(
            string: "*",
            attributes: [
                .font: LabelConfiguration.bodyMedium14.font,
                .foregroundColor: UIColor.primaryRed
            ]
        ))
        $0.attributedText = attr
    }

    let nameTextField = UITextField().then {
        $0.font = LabelConfiguration.body14.font
        $0.textColor = .gray800
        $0.placeholder = "프리셋 이름을 입력해주세요"
        $0.borderStyle = .none
        $0.setLeftPadding(4)
    }

    private let nameTextFieldUnderline = UIView().then {
        $0.backgroundColor = .gray100
    }

    let countLabel = UILabel().then {
        $0.font = LabelConfiguration.body12.font
        $0.textColor = .gray500
    }

    let addButton = UIButton().then {
        $0.setImage(UIImage(systemName: "plus"), for: .normal)
        $0.tintColor = .accent
    }

    let emptyProductCardView = EmptyProductCardView().then {
        $0.isHidden = true
    }

    lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout()).then {
        $0.backgroundColor = .white
        $0.showsVerticalScrollIndicator = false
        $0.register(ProductCell.self, forCellWithReuseIdentifier: ProductCell.id)
    }

    let deleteButton = UIButton().then {
        $0.titleLabel?.font = LabelConfiguration.bodyMedium14.font
        $0.setTitle("삭제", for: .normal)
        $0.setTitleColor(.primaryRed, for: .normal)
        $0.backgroundColor = .primaryLightRed
        $0.layer.cornerRadius = 8
    }

    let saveButton = UIButton().then {
        $0.titleLabel?.font = LabelConfiguration.bodyMedium14.font
        $0.setTitle("저장", for: .normal)
        $0.setTitleColor(.white, for: .normal)
        $0.backgroundColor = .accent
        $0.layer.cornerRadius = 12
    }

    private let bottomButtonStack = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 16
        $0.distribution = .fill
        $0.alignment = .center
    }

    let swipeDeleteRelay = PublishRelay<IndexPath>()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        configCollectionViewLayout()
        setLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension WidgetPresetEditView {
    private func setLayout() {
        [deleteButton, saveButton].forEach { bottomButtonStack.addArrangedSubview($0) }
        [nameLabel, nameTextField, nameTextFieldUnderline,
         countLabel, addButton,
         emptyProductCardView, collectionView,
         bottomButtonStack].forEach { addSubview($0) }

        nameLabel.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(16)
            $0.leading.equalToSuperview().offset(20)
        }

        nameTextField.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(36)
        }

        nameTextFieldUnderline.snp.makeConstraints {
            $0.top.equalTo(nameTextField.snp.bottom)
            $0.leading.trailing.equalTo(nameTextField)
            $0.height.equalTo(1)
        }

        countLabel.snp.makeConstraints {
            $0.top.equalTo(nameTextFieldUnderline.snp.bottom).offset(32)
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalTo(addButton)
        }

        addButton.snp.makeConstraints {
            $0.top.equalTo(nameTextFieldUnderline.snp.bottom).offset(32)
            $0.trailing.equalToSuperview().offset(-16)
            $0.size.equalTo(20)
        }

        emptyProductCardView.snp.makeConstraints {
            $0.top.equalTo(addButton.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(addButton.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(bottomButtonStack.snp.top).offset(-8)
        }

        bottomButtonStack.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(safeAreaLayoutGuide).offset(-8)
        }

        deleteButton.snp.makeConstraints {
            $0.width.equalTo(89)
            $0.height.equalTo(44)
        }

        saveButton.snp.makeConstraints {
            $0.height.equalTo(48)
        }
    }
}

extension WidgetPresetEditView {
    private func configCollectionViewLayout() {
        let layout = UICollectionViewCompositionalLayout { _, environment in
            var config = UICollectionLayoutListConfiguration(appearance: .plain)
            config.showsSeparators = false
            config.backgroundColor = .clear
            config.trailingSwipeActionsConfigurationProvider = { [weak self] indexPath in
                let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] _, _, completion in
                    self?.swipeDeleteRelay.accept(indexPath)
                    completion(true)
                }
                deleteAction.image = UIImage(systemName: "trash")
                return UISwipeActionsConfiguration(actions: [deleteAction])
            }
            let section = NSCollectionLayoutSection.list(using: config, layoutEnvironment: environment)
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)
            section.interGroupSpacing = 8
            return section
        }
        collectionView.setCollectionViewLayout(layout, animated: false)
    }
}

extension WidgetPresetEditView {
    func updateCountLabel(count: Int) {
        countLabel.text = "전체(\(count)/5)"
    }

    func updateDeleteButton(isVisible: Bool) {
        deleteButton.isHidden = !isVisible
    }

    func updateProductsVisibility(isEmpty: Bool) {
        emptyProductCardView.isHidden = !isEmpty
        collectionView.isHidden = isEmpty
    }
}

private extension UITextField {
    func setLeftPadding(_ width: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: width, height: frame.height))
        leftView = paddingView
        leftViewMode = .always
    }
}
