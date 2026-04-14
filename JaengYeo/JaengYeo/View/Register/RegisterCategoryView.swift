//
//  RegisterCategoryView.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/14/26.
//

import UIKit
import SnapKit
import Then

final class RegisterCategoryView: UIView {

    // MARK: - Components

    let dimmingView = UIView().then {
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        $0.alpha = 0
    }

    let contentView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 20
        $0.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        $0.clipsToBounds = true
    }

    private let handleView = UIView().then {
        $0.backgroundColor = .gray300
        $0.layer.cornerRadius = 2.5
    }

    private let pageContainerView = UIView()

    lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: createLayout()
    ).then {
        $0.backgroundColor = .white
        $0.isPagingEnabled = true
        $0.showsHorizontalScrollIndicator = false
    }

    let pageControl = UIPageControl().then {
        $0.currentPage = 0
        $0.pageIndicatorTintColor = .gray200
        $0.currentPageIndicatorTintColor = .accent
    }

    let confirmButton = UIButton().then {
        $0.setTitle("완료", for: .normal)
        $0.titleLabel?.font = LabelConfiguration.bodyMedium14.font
        $0.backgroundColor = .accent
        $0.layer.cornerRadius = 12
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Public

extension RegisterCategoryView {
    func configurePageControl(itemCount: Int, itemsPerPage: Int) {
        let pageCount = Int(ceil(Double(itemCount) / Double(itemsPerPage)))
        pageControl.numberOfPages = pageCount
        pageControl.isHidden = pageCount <= 1
        pageControl.currentPage = min(pageControl.currentPage, max(pageCount - 1, 0))
    }

    func scrollToPage(_ page: Int) {
        let offsetX = CGFloat(page) * collectionView.bounds.width
        collectionView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: true)
    }
}

// MARK: - Compositional Layout

private extension RegisterCategoryView {
    func createLayout() -> UICollectionViewLayout {
        let item = NSCollectionLayoutItem(
            layoutSize: .init(
                widthDimension: .fractionalWidth(0.2),
                heightDimension: .fractionalHeight(1.0)
            )
        )

        let rowGroup = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(76)
            ),
            repeatingSubitem: item,
            count: 5
        )

        let pageGroup = NSCollectionLayoutGroup.vertical(
            layoutSize: .init(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(244)
            ),
            repeatingSubitem: rowGroup,
            count: 3
        )
        pageGroup.interItemSpacing = .fixed(8)

        let section = NSCollectionLayoutSection(group: pageGroup)

        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.scrollDirection = .horizontal

        return UICollectionViewCompositionalLayout(section: section, configuration: configuration)
    }
}

// MARK: - Layout

private extension RegisterCategoryView {
    func setLayout() {
        [dimmingView, contentView].forEach { addSubview($0) }
        [handleView, pageContainerView, pageControl, confirmButton].forEach { contentView.addSubview($0) }
        pageContainerView.addSubview(collectionView)

        dimmingView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        contentView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.top.greaterThanOrEqualToSuperview()
        }
        handleView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(40)
            $0.height.equalTo(5)
        }
        pageContainerView.snp.makeConstraints {
            $0.top.equalTo(handleView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(244)
        }
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        pageControl.snp.makeConstraints {
            $0.top.equalTo(pageContainerView.snp.bottom).offset(4)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(20)
        }
        confirmButton.snp.makeConstraints {
            $0.top.equalTo(pageControl.snp.bottom).offset(16)
            $0.trailing.equalToSuperview().inset(16)
            $0.width.equalTo(238)
            $0.height.equalTo(44)
            $0.bottom.equalTo(contentView.safeAreaLayoutGuide).offset(-8)
        }
    }
}
