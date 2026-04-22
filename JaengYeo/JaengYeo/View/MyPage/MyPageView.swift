//
//  MyPageView.swift
//  JaengYeo
//
//  Created by Codex on 4/20/26.
//

import SnapKit
import Then
import UIKit
import RxCocoa
import RxSwift

final class MyPageView: UIView {

    //MARK: - Properties
    private let disposeBag = DisposeBag()
    private let itemSelectedRelay = PublishRelay<MyPageItem>()
    private lazy var dataSource = configureDataSource()

    //MARK: - Components
    /// 마이페이지 항목 컬렉션 뷰
    private lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: createLayout()
    ).then {
        $0.backgroundColor = .white
        $0.showsVerticalScrollIndicator = false
    }

    //MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
        bind()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//MARK: - Public
extension MyPageView {
    /// 마이페이지 항목 선택 이벤트
    var itemSelected: Observable<MyPageItem> {
        itemSelectedRelay.asObservable()
    }

    /// 스냅샷 적용
    func applySnapshot(with sections: [MyPageSection]) {
        var snapshot = NSDiffableDataSourceSnapshot<MyPageSection, MyPageItem>()

        sections.forEach {
            snapshot.appendSections([$0])
            snapshot.appendItems($0.items, toSection: $0)
        }

        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

//MARK: - DataSource
extension MyPageView {
    /// 데이터소스 설정
    private func configureDataSource() -> UICollectionViewDiffableDataSource<
        MyPageSection,
        MyPageItem
    > {
        let cellRegistration = UICollectionView.CellRegistration<
            MyPageItemCell,
            MyPageItem
        > { cell, _, item in
            cell.updateUI(
                title: item.title,
                showsChevron: item.showsArrow,
                titleColor: item.menu == .logout ? .systemRed : .gray800
            )
        }

        let headerRegistration = UICollectionView.SupplementaryRegistration<
            MyPageSectionHeaderView
        >(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { [weak self] headerView, _, indexPath in
            guard let section = self?.dataSource.sectionIdentifier(
                for: indexPath.section
            ) else { return }

            headerView.updateUI(title: section.title)
        }

        let dataSource = UICollectionViewDiffableDataSource<
            MyPageSection,
            MyPageItem
        >(
            collectionView: collectionView
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
}

//MARK: - Compositional Layout
extension MyPageView {
    /// 컬렉션 뷰 레이아웃 생성
    private func createLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { _, _ in
            let item = NSCollectionLayoutItem(
                layoutSize: .init(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(24)
                )
            )

            let group = NSCollectionLayoutGroup.vertical(
                layoutSize: .init(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(24)
                ),
                subitems: [item]
            )

            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: .init(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(30)
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
                bottom: 32,
                trailing: 16
            )

            return section
        }
    }
}

//MARK: - Configure UI
extension MyPageView {
    /// UI 설정
    func configureUI() {
        backgroundColor = .white

        addSubview(collectionView)

        collectionView.snp.makeConstraints {
            $0.edges.equalTo(safeAreaLayoutGuide)
        }
    }
}

//MARK: - Binding
extension MyPageView {
    func bind() {
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
            .bind(to: itemSelectedRelay)
            .disposed(by: disposeBag)
    }
}

final class MyPageSectionHeaderView: UICollectionReusableView {

    //MARK: - Components
    private let titleLabel = StyledLabel(config: .body12).then {
        $0.numberOfLines = 1
        $0.updateColor(.gray300)
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
    }
}

//MARK: - Public
extension MyPageSectionHeaderView {
    /// 헤더 UI 업데이트
    func updateUI(title: String) {
        titleLabel.text = title
    }
}

//MARK: - Configure UI
extension MyPageSectionHeaderView {
    /// UI 설정
    func configureUI() {
        backgroundColor = .clear

        addSubview(titleLabel)

        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview()
        }
    }
}

#Preview {
    let view = MyPageView()
    view.applySnapshot(
        with: [
            MyPageSection(
                title: "고객 지원",
                items: [
                    MyPageItem(menu: .guide, title: "사용 설명서"),
                    MyPageItem(menu: .privacyPolicy, title: "개인정보 처리 방침"),
                    MyPageItem(menu: .appPermission, title: "앱 사용 권한 확인"),
                ]
            ),
            MyPageSection(
                title: "앱 정보",
                items: [
                    MyPageItem(menu: .feedback, title: "의견 보내기"),
                    MyPageItem(menu: .appVersion, title: "현재 버전 1.0"),
                    MyPageItem(menu: .iconCopyright, title: "아이콘 저작권 : icons8"),
                ]
            ),
        ]
    )
    return view
}
