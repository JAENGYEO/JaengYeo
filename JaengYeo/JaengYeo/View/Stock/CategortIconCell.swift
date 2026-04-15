//
//  CategortIconCell.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/15/26.
//


import SnapKit
import Then
import UIKit

final class CategortIconCell: UICollectionViewCell {

    static let id = "CategortIconCell"

    //MARK: - Components
    private let iconContainerView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 12
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.clear.cgColor
        $0.clipsToBounds = true
    }

    private let iconImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.tintColor = .accent
        $0.backgroundColor = .clear
    }

    override var isSelected: Bool {
        didSet {
            applySelectionState()
        }
    }

    //MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.image = nil
        isSelected = false
    }
}

//MARK: - Public
extension CategortIconCell {
    /// 아이콘 설정
    func updateUI(image: UIImage?) {
        iconImageView.image = image
        applySelectionState()
    }
}

//MARK: - Configure UI
private extension CategortIconCell {
    /// UI 설정
    func configureUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(iconContainerView)
        iconContainerView.addSubview(iconImageView)

        iconContainerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.size.equalTo(48)
        }

        iconImageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(28)
        }
    }

    /// 선택 상태 적용
    func applySelectionState() {
        iconContainerView.backgroundColor = isSelected ? .primary100 : .white
        //TODO: 아이콘 이미지 적용시 백그라운드 색상 clear로 변경
        iconImageView.backgroundColor = .clear
    }
}

#Preview {
    let cell = CategortIconCell()
    cell.updateUI(image: UIImage(named: "categoryIcon"))
    return cell
}
