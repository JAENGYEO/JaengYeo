//
//  CategoryIconsView.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/15/26.
//

import SnapKit
import Then
import UIKit

final class CategoryIconsView: UIView {

    //MARK: - Components
    /// 카테고리 컬렉션 뷰
    lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: createLayout()
    ).then {
        $0.backgroundColor = .white
        $0.showsHorizontalScrollIndicator = false
    }

    /// 완료 버튼
    let applyButton = StyledButton(
        title: "완료",
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

//MARK: - Compositional Layout
private extension CategoryIconsView {
    /// 컬렉션 뷰 레이아웃 생성
    func createLayout() -> UICollectionViewLayout {
        let item = NSCollectionLayoutItem(
            layoutSize: .init(
                widthDimension: .absolute(48),
                heightDimension: .absolute(48)
            )
        )

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(48)
            ),
            repeatingSubitem: item,
            count: 5
        )
        group.interItemSpacing = .fixed(16)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 16
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: 16,
            bottom: 0,
            trailing: 16
        )

        return UICollectionViewCompositionalLayout(section: section)
    }
}

//MARK: - Configure UI
private extension CategoryIconsView {
    /// UI 설정
    func configureUI() {
        backgroundColor = .white

        addSubview(collectionView)
        addSubview(applyButton)

        collectionView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(applyButton.snp.top).offset(-16)
        }

        applyButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview()
            $0.height.equalTo(44)
        }
    }
}

#Preview {
    let viewController = UIViewController()
    let categoryIconsView = CategoryIconsView()

    viewController.view.backgroundColor = .white
    viewController.view.addSubview(categoryIconsView)

    categoryIconsView.snp.makeConstraints {
        $0.edges.equalTo(viewController.view.safeAreaLayoutGuide)
    }

    return viewController
}
