//
//  CategorySelectionItemCell.swift
//  JaengYeo
//
//  Created by Codex on 4/12/26.
//

import SnapKit
import Then
import UIKit

final class CategorySelectionItemCell: UICollectionViewCell {

    //MARK: - Properties
    private var isItemSelected = false {
        didSet {
            applySelectionState()
        }
    }
    
    //MARK: - Components
    private let itemContainerView = UIView().then {
        $0.layer.cornerRadius = 8
        $0.clipsToBounds = true
    }

    private let imageBackgroundView = UIView().then {
        $0.backgroundColor = .gray200
        $0.layer.cornerRadius = 6
        $0.clipsToBounds = true
    }

    private let imageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
    }

    private let titleLabel = StyledLabel(config: .body12).then {
        $0.textAlignment = .center
        $0.numberOfLines = 1
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
        titleLabel.text = nil
        imageView.image = nil
        isItemSelected = false
    }
}

//MARK: - Update UI
extension CategorySelectionItemCell {
    func updateUI(
        title: String,
        image: UIImage?,
        isSelect: Bool
    ) {
        titleLabel.text = title
        imageView.image = image
        isItemSelected = isSelect
    }
}

//MARK: - Configure UI
private extension CategorySelectionItemCell {
    func configureUI() {
        contentView.addSubview(itemContainerView)
        itemContainerView.addSubview(imageBackgroundView)
        itemContainerView.addSubview(titleLabel)
        imageBackgroundView.addSubview(imageView)

        itemContainerView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.equalTo(60)
            $0.height.equalTo(76)
        }

        imageBackgroundView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.leading.trailing.equalToSuperview().inset(10)
            $0.size.equalTo(40)
        }

        imageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(24)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(imageBackgroundView.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview().inset(4)
            $0.height.greaterThanOrEqualTo(20)
        }
    }

    func applySelectionState() {
        itemContainerView.backgroundColor = isItemSelected ? .primary100 : .clear
        //TODO: 아이콘 이미지 적용시 백그라운드 색상 clear로 변경
        imageBackgroundView.backgroundColor = .gray200
    }
}

#Preview {
    let cell = CategorySelectionItemCell()
    cell.updateUI(
        title: "전체",
        image: UIImage(named: "categoryIcon"),
        isSelect: false
    )
    return cell
}
