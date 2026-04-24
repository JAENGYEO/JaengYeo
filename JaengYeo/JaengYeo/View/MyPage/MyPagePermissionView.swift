//
//  MyPagePermissionView.swift
//  JaengYeo
//
//  Created by Codex on 4/20/26.
//

import RxRelay
import RxSwift
import SnapKit
import Then
import UIKit

final class MyPagePermissionView: UIView {

    //MARK: - Enum
    private enum Section {
        case main
    }

    //MARK: - Properties
    private let permissionToggledRelay = PublishRelay<(MyPagePermissionType, Bool)>()
    private lazy var dataSource = configureDataSource()

    //MARK: - Components
    /// 권한 목록 컬렉션 뷰
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
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//MARK: - Public
extension MyPagePermissionView {
    /// 권한 토글 변경 이벤트
    var permissionToggled: Observable<(MyPagePermissionType, Bool)> {
        permissionToggledRelay.asObservable()
    }

    /// 스냅샷 적용
    func applySnapshot(with items: [MyPagePermissionItem]) {
        var snapshot = NSDiffableDataSourceSnapshot<
            Section,
            MyPagePermissionItem
        >()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

//MARK: - DataSource
extension MyPagePermissionView {
    /// 데이터소스 설정
    private func configureDataSource() -> UICollectionViewDiffableDataSource<
        Section,
        MyPagePermissionItem
    > {
        let cellRegistration = UICollectionView.CellRegistration<
            MyPagePermissionCell,
            MyPagePermissionItem
        > { [weak self] cell, _, item in
            cell.updateUI(
                title: item.title,
                isOn: item.isAllowed
            ) { [weak self] isOn in
                self?.permissionToggledRelay.accept((item.type, isOn))
            }
        }

        return UICollectionViewDiffableDataSource<
            Section,
            MyPagePermissionItem
        >(
            collectionView: collectionView
        ) { collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(
                using: cellRegistration,
                for: indexPath,
                item: item
            )
        }
    }
}

//MARK: - Compositional Layout
extension MyPagePermissionView {
    /// 컬렉션 뷰 레이아웃 생성
    private func createLayout() -> UICollectionViewLayout {
        let item = NSCollectionLayoutItem(
            layoutSize: .init(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(48)
            )
        )

        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: .init(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(48)
            ),
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 16,
            leading: 0,
            bottom: 20,
            trailing: 0
        )

        return UICollectionViewCompositionalLayout(section: section)
    }
}

//MARK: - Configure UI
extension MyPagePermissionView {
    /// UI 설정
    func configureUI() {
        backgroundColor = .white

        addSubview(collectionView)

        collectionView.snp.makeConstraints {
            $0.edges.equalTo(safeAreaLayoutGuide)
        }
    }
}

#Preview {
    let view = MyPagePermissionView()
    view.applySnapshot(
        with: [
            MyPagePermissionItem(
                type: .camera,
                title: "카메라",
                isAllowed: true
            ),
            MyPagePermissionItem(
                type: .notification,
                title: "알림",
                isAllowed: false
            ),
        ]
    )
    return view
}
