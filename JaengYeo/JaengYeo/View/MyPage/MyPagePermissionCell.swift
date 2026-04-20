//
//  MyPagePermissionCell.swift
//  JaengYeo
//
//  Created by Codex on 4/20/26.
//

import SnapKit
import Then
import UIKit

final class MyPagePermissionCell: UICollectionViewCell {

    //MARK: - Properties
    private var onSwitchChanged: ((Bool) -> Void)?

    //MARK: - Components
    /// 권한 타이틀
    private let titleLabel = StyledLabel(config: .bodyMedium14).then {
        $0.numberOfLines = 1
        $0.updateColor(.gray800)
    }

    /// 권한 토글
    private let permissionSwitch = UISwitch().then {
        $0.onTintColor = .accent
    }

    //MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
        configureAction()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        permissionSwitch.setOn(false, animated: false)
        onSwitchChanged = nil
    }
}

//MARK: - Public
extension MyPagePermissionCell {
    /// 셀 UI 업데이트
    func updateUI(
        title: String,
        isOn: Bool,
        onSwitchChanged: @escaping (Bool) -> Void
    ) {
        titleLabel.text = title
        permissionSwitch.setOn(isOn, animated: false)
        self.onSwitchChanged = onSwitchChanged
    }
}

//MARK: - Configure
extension MyPagePermissionCell {
    /// UI 설정
    func configureUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .white

        contentView.addSubview(titleLabel)
        contentView.addSubview(permissionSwitch)

        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(24)
            $0.centerY.equalToSuperview()
            $0.trailing.lessThanOrEqualTo(permissionSwitch.snp.leading).offset(-12)
        }

        permissionSwitch.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(24)
            $0.centerY.equalToSuperview()
        }
    }

    /// 액션 설정
    func configureAction() {
        permissionSwitch.addAction(
            UIAction { [weak self] _ in
                guard let self else { return }
                self.onSwitchChanged?(self.permissionSwitch.isOn)
            },
            for: .valueChanged
        )
    }
}

#Preview {
    let cell = MyPagePermissionCell()
    cell.updateUI(
        title: "카메라",
        isOn: true,
        onSwitchChanged: { _ in }
    )
    return cell
}
