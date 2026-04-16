//
//  CategorySelectionView.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/13/26.
//

import SnapKit
import Then
import UIKit

final class CategorySelectionView: UIView {

    //MARK: - Components
    /// 페이지 영역 뷰
    private let pageContainerView = UIView()

    /// 바텀 시트 시 뒷 배경
    let dimmingView = UIView().then {
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        $0.alpha = 0
    }

    /// 콘텐츠 컨테이너
    let contentView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 20
        $0.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        $0.clipsToBounds = true
    }

    /// 상단 핸들 뷰
    let handleView = UIView().then {
        $0.backgroundColor = .gray300
        $0.layer.cornerRadius = 2.5
    }
    
    /// 카테고리 컬렉션 뷰
    lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: createLayout()
    ).then {
        $0.backgroundColor = .white
        $0.isPagingEnabled = true
        $0.showsHorizontalScrollIndicator = false
    }

    /// 페이지 인디케이터
    let pageControl = UIPageControl().then {
        $0.currentPage = 0
        $0.pageIndicatorTintColor = .gray200
        $0.currentPageIndicatorTintColor = .accent
    }

    /// 초기화 버튼
    let resetButton = StyledButton(
        title: "초기화",
        titleConfiguration: .resetTitle,
        appearanceConfiguration: .textAppearance
    ).then {
        $0.setImage(UIImage(systemName: "arrow.counterclockwise"), for: .normal)
        $0.tintColor = .gray300
    }

    /// 필터 적용 버튼
    let applyButton = StyledButton(
        title: "0개 필터 적용",
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
extension CategorySelectionView {
    /// 페이지 컨트롤 설정
    func configurePageControl(
        itemCount: Int,
        itemsPerPage: Int
    ) {
        let pageCount = Int(ceil(Double(itemCount) / Double(itemsPerPage)))

        pageControl.numberOfPages = pageCount
        pageControl.isHidden = pageCount <= 1
        pageControl.currentPage = min(pageControl.currentPage, max(pageCount - 1, 0))
    }

    /// 페이지 이동
    func scrollToPage(_ page: Int) {
        let offsetX = CGFloat(page) * collectionView.bounds.width
        collectionView.setContentOffset(
            CGPoint(x: offsetX, y: 0),
            animated: true
        )
    }
}

//MARK: - Compositional Layout
private extension CategorySelectionView {
    /// 컬렉션 뷰 레이아웃 생성
    func createLayout() -> UICollectionViewLayout {
        /// 아이템
        let item = NSCollectionLayoutItem(
            layoutSize: .init(
                widthDimension: .fractionalWidth(0.2),
                heightDimension: .fractionalHeight(1.0)
            )
        )

        /// 5열 그룹
        let rowGroup = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(76)
            ),
            repeatingSubitem: item,
            count: 5
        )

        /// 3행 페이지 그룹
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

        return UICollectionViewCompositionalLayout(
            section: section,
            configuration: configuration
        )
    }
}

//MARK: - Configure UI
private extension CategorySelectionView {
    /// UI 설정
    func configureUI() {
        overrideUserInterfaceStyle = .light
        backgroundColor = .clear
        pageContainerView.backgroundColor = .white
        collectionView.backgroundColor = .white
        
        addSubview(dimmingView)
        addSubview(contentView)
        
        contentView.addSubview(handleView)
        contentView.addSubview(pageContainerView)
        contentView.addSubview(pageControl)
        contentView.addSubview(resetButton)
        contentView.addSubview(applyButton)
        
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
        
        pageControl.snp.makeConstraints {
            $0.top.equalTo(pageContainerView.snp.bottom).offset(4)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(20)
        }
        
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        resetButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalTo(applyButton)
            $0.width.equalTo(63)
            $0.height.equalTo(20)
        }
        
        applyButton.snp.makeConstraints {
            $0.top.equalTo(pageControl.snp.bottom).offset(16)
            $0.leading.greaterThanOrEqualTo(resetButton.snp.trailing).offset(42)
            $0.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(contentView.safeAreaLayoutGuide).inset(16)
            $0.width.greaterThanOrEqualTo(238)
            $0.height.equalTo(44)
        }
    }
}
