//
//  CategoryEditViewController.swift
//  JaengYeo
//
//  Created by Codex on 4/14/26.
//

import SnapKit
import Then
import UIKit
import RxCocoa
import RxSwift

/// 분류 편집 화면 이벤트 전달
protocol CategoryEditViewControllerDelegate: AnyObject {
    func categoryEditViewController(
        _ viewController: CategoryEditViewController,
        didSelect mode: CategoryEditMode
    )
}

final class CategoryEditViewController: UIViewController {

    //MARK: - Enum
    private enum Section: CaseIterable {
        case midCategory
        case subCategory

        var title: String {
            switch self {
            case .midCategory:
                return "중분류 (위치)"
            case .subCategory:
                return "소분류 (종류)"
            }
        }
        
        var target: CategoryEditTarget {
            switch self {
            case .midCategory:
                return .midCategory
            case .subCategory:
                return .subCategory
            }
        }
    }

    //MARK: - ViewModel
    private let viewModel: CategoryEditViewModel

    //MARK: - Properties
    private let disposeBag = DisposeBag()
    /// 삭제할 분류 전달
    private let deleteItemSelectedRelay = PublishRelay<(CategoryEditTarget, CategoryEditItem)>()
    private lazy var dataSource = configureDataSource()
    weak var delegate: CategoryEditViewControllerDelegate?

    //MARK: - Components
    /// 메인 카테고리 세그먼트
    private let mainCategorySegment = UISegmentedControl().then {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: LabelConfiguration.bodyMedium14.font,
            .foregroundColor: UIColor.gray800
        ]
        let selectAttributes:
        [NSAttributedString.Key: Any] = [
            .font: LabelConfiguration.bodyMedium14.font,
            .foregroundColor: UIColor.accent
        ]
        $0.setTitleTextAttributes(attributes, for: .normal)
        $0.setTitleTextAttributes(selectAttributes, for: .selected)

        $0.selectedSegmentTintColor = .white
    }

    /// 분류 목록 컬렉션 뷰
    private lazy var categoryCollectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: createLayout()
    ).then {
        $0.backgroundColor = .gray50
        $0.contentInset.top = 12
        $0.showsVerticalScrollIndicator = false
    }

    //MARK: - Init
    init(viewModel: CategoryEditViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureUI()
        bind()
    }
}

//MARK: - Bind
private extension CategoryEditViewController {
    func bind() {
        let input = CategoryEditViewModel.Input(
            viewDidLoad: Observable.just(()),
            mainCategorySelected: mainCategorySegment.rx.selectedSegmentIndex
                .asObservable()
                .filter { $0 >= 0 },
            deleteItemSelected: deleteItemSelectedRelay.asObservable()
        )

        let output = viewModel.transform(input)

        /// 메인 카테고리 바인딩
        output.mainCategories
            .bind(onNext: { [weak self] categories in
                guard let self else { return }

                self.mainCategorySegment.removeAllSegments()
                categories.enumerated().forEach { index, title in
                    self.mainCategorySegment.insertSegment(
                        withTitle: title,
                        at: index,
                        animated: false
                    )
                }
                mainCategorySegment.selectedSegmentIndex = 0
            })
            .disposed(by: disposeBag)

        /// 분류 목록 바인딩
        Observable.combineLatest(
            output.presentMidCategoryItems,
            output.presentSubCategoryItems
        )
        .bind(onNext: { [weak self] midItems, subItems in
            guard let self else { return }
            self.applySnapshot(
                midItems: midItems,
                subItems: subItems
            )
        })
        .disposed(by: disposeBag)
        
        /// 아이템 선택 이벤트
        categoryCollectionView.rx.itemSelected
            .compactMap { [weak self] indexPath -> CategoryEditMode? in
                self?.makeEditMode(at: indexPath)
            }
            .bind(onNext: { [weak self] mode in
                guard let self else { return }
                self.delegate?.categoryEditViewController(
                    self,
                    didSelect: mode
                )
            })
            .disposed(by: disposeBag)
    }
}

//MARK: - DataSource
private extension CategoryEditViewController {

    /// 데이터소스 설정
    private func configureDataSource() -> UICollectionViewDiffableDataSource<
        Section,
        CategoryEditItem
    > {
        let cellRegistration = UICollectionView.CellRegistration<
            CategorySelectionItemCell,
            CategoryEditItem
        > { [weak self] cell, _, item in
            guard let self else { return }
            cell.updateUI(
                title: item.title,
                image: item.image,
                isSelect: false,
                showsDeleteButton: item.userId != nil
            )
            
            cell.bindDeleteButtonTap { [weak self] in
                    guard let self else { return }

                    AlertController.rx.alert(
                        on: self,
                        image: UIImage(named: "alartRed") ?? UIImage(),
                        title: "분류 삭제",
                        message: "\(item.title) 분류를 삭제하시겠습니까?",
                        actions: [
                            .cancel("취소"),
                            .destructive("삭제")
                        ]
                    )
                    .filter { $0.title == "삭제" }
                    .subscribe(onNext: { [weak self] _ in
                        self?.deleteItem(item)
                    })
                    .disposed(by: self.disposeBag)
                }
        }

        let headerRegistration = UICollectionView.SupplementaryRegistration<
            UICollectionViewListCell
        >(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { [weak self] headerView, _, indexPath in
            guard let section = self?.dataSource.sectionIdentifier(
                for: indexPath.section
            ) else { return }

            var contentConfiguration = UIListContentConfiguration.plainHeader()
            contentConfiguration.text = section.title
            contentConfiguration.textProperties.font = LabelConfiguration.bodyMedium14.font
            contentConfiguration.textProperties.color = .gray800
            headerView.contentConfiguration = contentConfiguration
            headerView.backgroundConfiguration = .clear()
        }

        let dataSource = UICollectionViewDiffableDataSource<
            Section,
            CategoryEditItem
        >(
            collectionView: categoryCollectionView
        ) { collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(
                using: cellRegistration,
                for: indexPath,
                item: item
            )
        }

        dataSource.supplementaryViewProvider = {
            collectionView,
            _,
            indexPath in
            collectionView.dequeueConfiguredReusableSupplementary(
                using: headerRegistration,
                for: indexPath
            )
        }

        return dataSource
    }

    /// 스냅샷 적용
    func applySnapshot(
        midItems: [CategoryEditItem],
        subItems: [CategoryEditItem]
    ) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, CategoryEditItem>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(
            midItems + [makeAddItem(section: .midCategory)],
            toSection: .midCategory
        )
        snapshot.appendItems(
            subItems + [makeAddItem(section: .subCategory)],
            toSection: .subCategory
        )
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    /// 추가 아이템 생성
    private func makeAddItem(section: Section) -> CategoryEditItem {
        CategoryEditItem(
            id: "\(section)-add",
            title: "추가",
            image: UIImage(named: "iconSelectIcon"),
            iconName: "iconSelectIcon",
            userId: nil
        )
    }
    
    /// 화면 이동 모드 생성
    func makeEditMode(at indexPath: IndexPath) -> CategoryEditMode? {
        guard
            let section = dataSource.sectionIdentifier(for: indexPath.section),
            let item = dataSource.itemIdentifier(for: indexPath),
            let mainCategory = mainCategorySegment.titleForSegment(
                at: mainCategorySegment.selectedSegmentIndex
            )
        else { return nil }
        
        if item.id.hasSuffix("-add") {
            return .add(section.target, mainCategory)
        }
        
        guard item.userId != nil else { return nil }
        return .edit(section.target, item, mainCategory)
    }
    
    /// 삭제 아이템 전달
    func deleteItem(_ item: CategoryEditItem) {
        //TODO: 삭제 알림 화면 추가 필요
        let snapshot = dataSource.snapshot()
        guard
            item.userId != nil,
            let section = snapshot.sectionIdentifiers.first(where: {
                snapshot.itemIdentifiers(inSection: $0).contains(item)
            })
        else { return }
        deleteItemSelectedRelay.accept((section.target, item))
    }
}

//MARK: - Compositional Layout
private extension CategoryEditViewController {
    /// 컬렉션 뷰 레이아웃 생성
    func createLayout() -> UICollectionViewLayout {
        let item = NSCollectionLayoutItem(
            layoutSize: .init(
                widthDimension: .fractionalWidth(0.2),
                heightDimension: .absolute(76)
            )
        )

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(76)
            ),
            repeatingSubitem: item,
            count: 5
        )
        group.interItemSpacing = .fixed(10)

        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: .init(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(36)
            ),
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )

        let section = NSCollectionLayoutSection(group: group)
        section.boundarySupplementaryItems = [header]
        section.interGroupSpacing = 8
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 8,
            leading: 16,
            bottom: 24,
            trailing: 16
        )

        return UICollectionViewCompositionalLayout(section: section)
    }
}

//MARK: - Configure UI
private extension CategoryEditViewController {
    /// 네비게이션 바 설정
    func configureNavigationBar() {
        title = "분류 편집"
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .font: LabelConfiguration.titleSemi18.font,
            .foregroundColor: UIColor.gray800
        ]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .gray800
    }

    /// UI 설정
    func configureUI() {
        view.backgroundColor = .white
        view.addSubview(mainCategorySegment)
        view.addSubview(categoryCollectionView)

        mainCategorySegment.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(40)
        }
        
        categoryCollectionView.snp.makeConstraints {
            $0.top.equalTo(mainCategorySegment.snp.bottom).offset(12)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }
}

#Preview {
    UINavigationController(
        rootViewController: CategoryEditViewController(
            viewModel: CategoryEditViewModel(coreDataManager: CoreDataManager())
        )
    )
}
