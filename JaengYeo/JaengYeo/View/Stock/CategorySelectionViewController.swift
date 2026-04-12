//
//  CategorySelectionViewController.swift
//  JaengYeo
//
//  Created by Codex on 4/12/26.
//

import RxCocoa
import RxRelay
import RxSwift
import SnapKit
import Then
import UIKit

final class CategorySelectionViewController: UIViewController {

    //MARK: - Enum
    private enum Section {
        case main
    }

    //MARK: - ViewModel
    private let viewModel: CategorySelectionViewModel

    //MARK: - Properties
    private let disposeBag = DisposeBag()
    /// 페이지당 아이템 개수
    private let itemsPerPage = 15
    private lazy var dataSource = configureDataSource()
    /// 적용 결과 전달
    var onApply: (([String]) -> Void)?

    //MARK: - Components
    /// 페이지 영역 뷰
    private let pageContainerView = UIView()

    /// 카테고리 컬렉션 뷰
    private lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: createLayout()
    ).then {
        $0.backgroundColor = .white
        $0.isPagingEnabled = true
        $0.showsHorizontalScrollIndicator = false
    }

    /// 페이지 인디케이터
    private let pageControl = UIPageControl().then {
        $0.currentPage = 0
        $0.pageIndicatorTintColor = .gray200
        $0.currentPageIndicatorTintColor = .accent
    }

    /// 초기화 버튼
    private let resetButton = StyledButton(
        title: "초기화",
        titleConfiguration: .resetTitle,
        appearanceConfiguration: .textAppearance
    ).then {
        $0.setImage(UIImage(systemName: "arrow.counterclockwise"), for: .normal)
        $0.tintColor = .gray300
    }

    /// 필터 적용 버튼
    private let applyButton = StyledButton(
        title: "0개 필터 적용",
        titleConfiguration: .defaultTitle,
        appearanceConfiguration: .defaultAppearance
    )

    //MARK: - Init
    init(items: [CategorySelectionItem] = []) {
        self.viewModel = CategorySelectionViewModel(items: items)
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
        preferredContentSize = CGSize(width: 0, height: 356)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureSheet()
        configureUI()
        bind()
    }
}

//MARK: - Binding
extension CategorySelectionViewController {
    fileprivate func bind() {
        let itemSelectionToggledRelay = PublishRelay<CategorySelectionItem>()

        /// 아이템 선택 이벤트
        collectionView.rx.itemSelected
            .do(onNext: { [weak self] indexPath in
                self?.collectionView.deselectItem(
                    at: indexPath,
                    animated: false
                )
            })
            .compactMap { [weak self] indexPath in
                self?.dataSource.itemIdentifier(for: indexPath)
            }
            .bind(to: itemSelectionToggledRelay)
            .disposed(by: disposeBag)

        /// 페이지 변경 이벤트
        collectionView.rx.contentOffset
            .compactMap { [weak self] contentOffset -> Int? in
                guard let self, self.collectionView.bounds.width > 0 else { return nil }
                return Int(round(contentOffset.x / self.collectionView.bounds.width))
            }
            .distinctUntilChanged()
            .bind(onNext: { [weak self] page in
                self?.pageControl.currentPage = page
            })
            .disposed(by: disposeBag)

        /// 페이지 컨트롤 이벤트
        pageControl.rx.controlEvent(.valueChanged)
            .bind(onNext: { [weak self] in
                guard let self else { return }
                self.scrollToPage(self.pageControl.currentPage)
            })
            .disposed(by: disposeBag)
        
        /// ViewModel 입력값
        let input = CategorySelectionViewModel.Input(
            itemSelectionToggled: itemSelectionToggledRelay.asObservable(),
            resetTapped: resetButton.rx.tap.asObservable(),
            applyTapped: applyButton.rx.tap.asObservable()
        )

        let output = viewModel.transform(input)

        /// 아이템 목록 바인딩
        output.items
            .bind(onNext: { [weak self] items in
                guard let self else { return }
                self.configurePageControl(itemCount: items.count)
                self.applySnapshot(with: items)
            })
            .disposed(by: disposeBag)

        /// 적용 버튼 타이틀 바인딩
        output.applyButtonTitle
            .bind(onNext: { [weak self] title in
                guard let self else { return }
                self.applyButton.updateTitle(title)
            })
            .disposed(by: disposeBag)

        /// 적용 결과 바인딩
        output.appliedItemIDs
            .bind(onNext: { [weak self] selectedItemIDs in
                guard let self else { return }
                self.onApply?(selectedItemIDs)
                self.dismiss(animated: true)
            })
            .disposed(by: disposeBag)
    }
}

//MARK: - DataSource
extension CategorySelectionViewController {
    /// 데이터소스 설정
    private func configureDataSource() -> UICollectionViewDiffableDataSource<Section, CategorySelectionItem> {
        let cellCategory = UICollectionView.CellRegistration<CategorySelectionItemCell, CategorySelectionItem> {
            cell, indexPath, item in
            cell.updateUI(
                title: item.title,
                image: item.image,
                isSelect: item.isSelect
            )
        }
        
        return UICollectionViewDiffableDataSource<Section, CategorySelectionItem>(
            collectionView: collectionView
        ) { collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(
                using: cellCategory,
                for: indexPath,
                item: item
            )
        }
    }
    
    /// 스냅샷 적용
    func applySnapshot(with datas: [CategorySelectionItem]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, CategorySelectionItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(datas, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    /// 페이지 컨트롤 설정
    private func configurePageControl(itemCount: Int) {
        let pageCount = Int(ceil(Double(itemCount) / Double(itemsPerPage)))

        pageControl.numberOfPages = pageCount
        pageControl.isHidden = pageCount <= 1
        pageControl.currentPage = min(pageControl.currentPage, max(pageCount - 1, 0))
    }

    /// 페이지 이동
    private func scrollToPage(_ page: Int) {
        let offsetX = CGFloat(page) * collectionView.bounds.width
        collectionView.setContentOffset(
            CGPoint(x: offsetX, y: 0),
            animated: true
        )
    }
}

//MARK: - compositional layout
extension CategorySelectionViewController {

    /// 컬렉션 뷰 레이아웃 생성
    private func createLayout() -> UICollectionViewLayout {

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
extension CategorySelectionViewController {
    /// 시트 설정
    private func configureSheet() {
        guard let sheetPresentationController else { return }

        sheetPresentationController.prefersGrabberVisible = true
        sheetPresentationController.preferredCornerRadius = 16
        sheetPresentationController.detents = [
            .custom { _ in 356 }
        ]
    }

    /// UI 설정
    private func configureUI() {
        view.backgroundColor = .white

        view.addSubview(pageContainerView)
        view.addSubview(pageControl)
        view.addSubview(resetButton)
        view.addSubview(applyButton)

        pageContainerView.addSubview(collectionView)

        pageContainerView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(244)
        }

        pageControl.snp.makeConstraints {
            $0.top.equalTo(pageContainerView.snp.bottom).offset(4)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(20)
        }

        collectionView.snp.makeConstraints {
            $0.top.bottom.leading.trailing.equalToSuperview()
        }

        resetButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalTo(applyButton)
            $0.width.equalTo(63)
            $0.height.equalTo(20)
        }

        applyButton.snp.makeConstraints {
            $0.leading.greaterThanOrEqualTo(resetButton.snp.trailing).offset(42)
            $0.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.width.greaterThanOrEqualTo(238)
            $0.height.equalTo(44)
        }
    }
}

#Preview {
    CategorySelectionViewController(
        items: (1...20).map {
            CategorySelectionItem(
                id: "\($0)",
                title: "항목\($0)",
                image: UIImage(named: "Category"),
                isSelect: false
            )
        }
    )
}
