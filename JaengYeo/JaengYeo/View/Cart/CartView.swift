//
//  CartView.swift
//  JaengYeo
//
//  Created by Hanjuheon on 5/1/26.
//

import UIKit
import SnapKit
import Then
import RxCocoa
import RxRelay
import RxSwift

final class CartView: UIView {

    //MARK: - Enum
    enum Section {
        case main
    }

    //MARK: - Properties
    private let disposeBag = DisposeBag()
    private let itemSelectedRelay = PublishRelay<CartItem>()
    private let itemDeletedRelay = PublishRelay<CartItem>()
    private let itemQuantityIncreasedRelay = PublishRelay<CartItem>()
    private let itemQuantityDecreasedRelay = PublishRelay<CartItem>()
    private let swipeDeleteRelay = PublishRelay<IndexPath>()
    private lazy var dataSource = configureDataSource()

    //MARK: - Components
    private let infoView = UIView().then {
        $0.backgroundColor = .white
    }

    private let totalCountLabel = StyledLabel(
        config: LabelConfiguration.body12.updatingColor(color: .gray500)
    ).then {
        $0.text = "총 0개"
    }

    private let sortedButton = UIButton(configuration: .plain()).then {
        var config = UIButton.Configuration.plain()
        var title = AttributedString("최근 등록순")
        title.font = .systemFont(ofSize: 12, weight: .regular)
        title.foregroundColor = .gray800

        let symbolConfig = UIImage.SymbolConfiguration(
            pointSize: 10,
            weight: .medium
        )

        config.attributedTitle = title
        config.image = UIImage(
            systemName: "chevron.down",
            withConfiguration: symbolConfig
        )
        config.baseForegroundColor = .gray800
        config.imagePlacement = .trailing
        config.imagePadding = 1
        config.contentInsets = .zero
        $0.configuration = config
    }

    private lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: createLayout()
    ).then {
        $0.backgroundColor = .white
        $0.showsVerticalScrollIndicator = false
    }

    private let confirmButton = StyledButton(
        title: "구매 확정",
        titleConfiguration: .defaultTitle,
        appearanceConfiguration: .defaultAppearance
    )

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
extension CartView {
    /// 상품 셀 선택 이벤트
    var itemSelected: Observable<CartItem> {
        itemSelectedRelay.asObservable()
    }

    /// 상품 삭제 이벤트
    var itemDeleted: Observable<CartItem> {
        itemDeletedRelay.asObservable()
    }

    /// 상품 수량 추가 이벤트
    var itemQuantityIncreased: Observable<CartItem> {
        itemQuantityIncreasedRelay.asObservable()
    }

    /// 상품 수량 차감 이벤트
    var itemQuantityDecreased: Observable<CartItem> {
        itemQuantityDecreasedRelay.asObservable()
    }

    /// 구매 확정 버튼 선택 이벤트
    var confirmButtonTap: Observable<Void> {
        confirmButton.rx.tap.asObservable()
    }

    /// 정렬 메뉴 설정
    func configureSortMenu(
        onSelect: @escaping (CartSortOption) -> Void
    ) {
        sortedButton.showsMenuAsPrimaryAction = true
        sortedButton.menu = UIMenu(
            children: CartSortOption.allCases.map { option in
                UIAction(title: option.rawValue) { _ in
                    onSelect(option)
                }
            }
        )
    }

    /// 정렬 타이틀 변경
    func updateSortTitle(_ title: String) {
        var config = sortedButton.configuration ?? .plain()
        var attributedTitle = AttributedString(title)
        attributedTitle.font = .systemFont(ofSize: 12, weight: .regular)
        attributedTitle.foregroundColor = .gray800
        config.attributedTitle = attributedTitle
        sortedButton.configuration = config
    }

    /// 스냅샷 적용
    func applySnapshot(with items: [CartItem]) {
        totalCountLabel.text = "총 \(items.count)개"

        var snapshot = NSDiffableDataSourceSnapshot<Section, CartItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}


//MARK: - Binding
private extension CartView {
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

        swipeDeleteRelay
            .compactMap { [weak self] indexPath in
                self?.dataSource.itemIdentifier(for: indexPath)
            }
            .bind(to: itemDeletedRelay)
            .disposed(by: disposeBag)
    }
}

//MARK: - DataSource
private extension CartView {
    /// 데이터소스 설정
    func configureDataSource() -> UICollectionViewDiffableDataSource<
        Section,
        CartItem
    > {
        let cellRegistration = UICollectionView.CellRegistration<
            CartProductCell,
            CartItem
        > { [weak self] cell, _, item in
            guard let self else { return }

            cell.resetExternalBindings()
            cell.updateUI(
                title: item.name,
                category: item.mainCategory,
                count: item.quantity,
                isSelected: false,
                showsCheckBox: false
            )

            cell.bindAddButtonTap { [weak self] in
                self?.itemQuantityIncreasedRelay.accept(item)
            }

            cell.bindDeleteButtonTap { [weak self] in
                self?.itemQuantityDecreasedRelay.accept(item)
            }
        }

        return UICollectionViewDiffableDataSource<Section, CartItem>(
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
private extension CartView {
    /// 컬렉션 뷰 레이아웃 생성
    func createLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { _, environment in
            var configuration = UICollectionLayoutListConfiguration(
                appearance: .plain
            )
            configuration.showsSeparators = false
            configuration.backgroundColor = .clear
            configuration.trailingSwipeActionsConfigurationProvider = { indexPath in
                let deleteAction = UIContextualAction(
                    style: .destructive,
                    title: nil
                ) { [weak self] _, _, completion in
                    self?.swipeDeleteRelay.accept(indexPath)
                    completion(true)
                }
                deleteAction.image = UIImage(systemName: "trash")

                let configuration = UISwipeActionsConfiguration(
                    actions: [deleteAction]
                )
                configuration.performsFirstActionWithFullSwipe = false
                return configuration
            }

            let section = NSCollectionLayoutSection.list(
                using: configuration,
                layoutEnvironment: environment
            )
            section.contentInsets = NSDirectionalEdgeInsets(
                top: 0,
                leading: 16,
                bottom: 0,
                trailing: 16
            )
            section.interGroupSpacing = 8
            return section
        }
    }
}

//MARK: - Configure UI
private extension CartView {
    /// UI 설정
    func configureUI() {
        backgroundColor = .white

        addSubview(infoView)
        addSubview(collectionView)
        addSubview(confirmButton)

        infoView.addSubview(totalCountLabel)
        infoView.addSubview(sortedButton)

        infoView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(40)
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(infoView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(confirmButton.snp.top).inset(16)
        }

        confirmButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(safeAreaLayoutGuide).inset(20)
            $0.height.equalTo(44)
        }

        totalCountLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalToSuperview().offset(16)
        }

        sortedButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview().inset(16)
        }
    }
}



#Preview {
    let viewController = UIViewController()
    let cartView = CartView()

    viewController.view.addSubview(cartView)
    cartView.snp.makeConstraints {
        $0.edges.equalToSuperview()
    }

    cartView.applySnapshot(
        with: [
            CartItem(
                id: UUID(),
                referenceId: nil,
                name: "토마토",
                mainCategory: "식재료",
                quantity: 8,
                createdAt: Date()
            ),
            CartItem(
                id: UUID(),
                referenceId: nil,
                name: "바나나",
                mainCategory: "식재료",
                quantity: 3,
                createdAt: Date()
            )
        ]
    )

    return viewController
}
