//
//  MyPageItemCell.swift
//  JaengYeo
//
//  Created by Codex on 4/20/26.
//

import SnapKit
import Then
import UIKit

final class MyPageItemCell: UICollectionViewListCell {

    //MARK: - Components
    /// 항목 타이틀
    private let titleLabel = StyledLabel(config: .bodyMedium14).then {
        $0.numberOfLines = 1
        $0.updateColor(.gray800)
    }

    /// 이동 표시 아이콘
    private let chevronImageView = UIImageView().then {
        $0.image = UIImage(named: "arrowIcon")?
            .withRenderingMode(.alwaysTemplate)
            .withHorizontallyFlippedOrientation()
        $0.contentMode = .scaleAspectFit
        $0.tintColor = .gray300
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
        chevronImageView.isHidden = false
    }
}

//MARK: - Public
extension MyPageItemCell {
    /// 셀 UI 업데이트
    func updateUI(
        title: String,
        showsChevron: Bool = true
    ) {
        titleLabel.text = title
        chevronImageView.isHidden = !showsChevron
    }
}

//MARK: - Configure UI
private extension MyPageItemCell {
    /// UI 설정
    func configureUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .white

        var backgroundConfiguration = UIBackgroundConfiguration.clear()
        backgroundConfiguration.backgroundColor = .white
        self.backgroundConfiguration = backgroundConfiguration

        contentView.addSubview(titleLabel)
        contentView.addSubview(chevronImageView)

        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.trailing.lessThanOrEqualTo(chevronImageView.snp.leading).offset(-12)
        }

        chevronImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.size.equalTo(16)
        }
    }
}

#Preview {
    let cell = MyPageItemCell()
    cell.updateUI(title: "사용 설명서")
    return cell
}
