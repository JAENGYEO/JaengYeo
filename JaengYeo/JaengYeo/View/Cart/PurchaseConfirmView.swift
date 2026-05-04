//
//  PurchaseConfirmView.swift
//  JaengYeo
//
//  Created by Hanjuheon on 5/3/26.
//

import UIKit
import SnapKit
import Then
import RxCocoa
import RxRelay
import RxSwift

/// 구매 확정 화면 셀 아이템
struct PurchaseConfirmItem: Hashable {
    let cartItem: CartItem
    let isSelected: Bool
}

final class PurchaseConfirmView: UIView {

    //MARK: - Enum
    enum Section {
        case main
    }

    //MARK: - Properties
    private let disposeBag = DisposeBag()
    private let selectAllTapRelay = PublishRelay<Void>()
    private let itemCheckTapRelay = PublishRelay<CartItem>()
    private let itemQuantityIncreasedRelay = PublishRelay<CartItem>()
    private let itemQuantityDecreasedRelay = PublishRelay<CartItem>()
    private lazy var dataSource = configureDataSource()

    //MARK: - Components
    /// 안내 배너
    private let bannerView = UIView().then {
        $0.backgroundColor = .gray50
        $0.layer.cornerRadius = 8
    }

    private let bannerIconView = UIImageView().then {
        $0.image = UIImage(systemName: "info.circle")
        $0.tintColor = .gray300
        $0.contentMode = .scaleAspectFit
    }

    private let bannerTextStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = -4
        $0.alignment = .leading
        $0.distribution = .fillEqually
    }

    private let bannerTitleLabel = StyledLabel(config: .bodyMedium14).then {
        $0.text = "실제 구매한 물품을 선택하고 수량을 확인해주세요"
        $0.numberOfLines = 1
        $0.updateColor(.gray800)
    }

    private let bannerDescriptionLabel = StyledLabel(
        config: LabelConfiguration.body12.updatingColor(color: .gray500)
    ).then {
        $0.text = "남은 수량은 구매 예정 목록에 유지됩니다."
        $0.numberOfLines = 1
    }

    /// 전체 선택 / 정렬 행
    private let controlRow = UIView().then {
        $0.backgroundColor = .white
    }

    private let selectAllButton = UIButton(type: .custom).then {
        $0.imageView?.contentMode = .scaleAspectFit
        $0.setImage(UIImage(named: "onIcon"), for: .normal)
    }

    private let selectAllLabel = StyledLabel(
        config: LabelConfiguration.body12.updatingColor(color: .gray500)
    ).then {
        $0.text = "전체 선택 (0/0)"
    }

    private let sortedButton = UIButton(configuration: .plain()).then {
        var config = UIButton.Configuration.plain()
        var title = AttributedString("최근 등록순")
        title.font = .systemFont(ofSize: 12, weight: .regular)
        title.foregroundColor = .gray800

        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 10, weight: .medium)
        config.attributedTitle = title
        config.image = UIImage(systemName: "chevron.down", withConfiguration: symbolConfig)
        config.baseForegroundColor = .gray800
        config.imagePlacement = .trailing
        config.imagePadding = 1
        config.contentInsets = .zero
        $0.configuration = config
    }

    /// 아이템 목록
    private lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: createLayout()
    ).then {
        $0.backgroundColor = .white
        $0.showsVerticalScrollIndicator = false
    }

    /// 재고 등록 버튼
    private let confirmButton = StyledButton(
        title: "재고 등록하기",
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
extension PurchaseConfirmView {
    /// 전체 선택 탭 이벤트
    var selectAllTap: Observable<Void> {
        selectAllTapRelay.asObservable()
    }

    /// 개별 아이템 체크 탭 이벤트
    var itemCheckTap: Observable<CartItem> {
        itemCheckTapRelay.asObservable()
    }

    /// 수량 추가 이벤트
    var itemQuantityIncreased: Observable<CartItem> {
        itemQuantityIncreasedRelay.asObservable()
    }

    /// 수량 차감 이벤트
    var itemQuantityDecreased: Observable<CartItem> {
        itemQuantityDecreasedRelay.asObservable()
    }

    /// 재고 등록하기 버튼 탭 이벤트
    var confirmButtonTap: Observable<Void> {
        confirmButton.rx.tap.asObservable()
    }

    /// 정렬 메뉴 설정
    func configureSortMenu(onSelect: @escaping (CartSortOption) -> Void) {
        sortedButton.showsMenuAsPrimaryAction = true
        sortedButton.menu = UIMenu(
            children: CartSortOption.allCases.map { option in
                UIAction(title: option.rawValue) { _ in onSelect(option) }
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
    func applySnapshot(items: [PurchaseConfirmItem]) {
        let selectedCount = items.filter { $0.isSelected }.count
        let totalCount = items.count
        selectAllLabel.text = "전체 선택 (\(selectedCount)/\(totalCount))"

        let allSelected = totalCount > 0 && selectedCount == totalCount
        selectAllButton.setImage(
            UIImage(named: allSelected ? "onIcon" : "offIcon"),
            for: .normal
        )

        var snapshot = NSDiffableDataSourceSnapshot<Section, PurchaseConfirmItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)
        snapshot.reconfigureItems(items)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

//MARK: - Binding
private extension PurchaseConfirmView {
    func bind() {
        selectAllButton.rx.tap
            .bind(to: selectAllTapRelay)
            .disposed(by: disposeBag)
    }
}

//MARK: - DataSource
private extension PurchaseConfirmView {
    func configureDataSource() -> UICollectionViewDiffableDataSource<Section, PurchaseConfirmItem> {
        let cellRegistration = UICollectionView.CellRegistration<
            CartProductCell,
            PurchaseConfirmItem
        > { [weak self] cell, _, item in
            guard let self else { return }

            cell.resetExternalBindings()
            cell.updateUI(
                title: item.cartItem.name,
                category: item.cartItem.mainCategory,
                count: item.cartItem.quantity,
                isSelected: item.isSelected,
                showsCheckBox: true
            )

            cell.bindCheckButtonTap { [weak self] in
                self?.itemCheckTapRelay.accept(item.cartItem)
            }

            cell.bindAddButtonTap { [weak self] in
                self?.itemQuantityIncreasedRelay.accept(item.cartItem)
            }

            cell.bindDeleteButtonTap { [weak self] in
                self?.itemQuantityDecreasedRelay.accept(item.cartItem)
            }
        }

        return UICollectionViewDiffableDataSource<Section, PurchaseConfirmItem>(
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
private extension PurchaseConfirmView {
    func createLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { _, environment in
            var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
            configuration.showsSeparators = false
            configuration.backgroundColor = .clear

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
private extension PurchaseConfirmView {
    func configureUI() {
        backgroundColor = .white

        addSubview(bannerView)
        addSubview(controlRow)
        addSubview(collectionView)
        addSubview(confirmButton)

        bannerView.addSubview(bannerIconView)
        bannerView.addSubview(bannerTextStackView)
        bannerTextStackView.addArrangedSubview(bannerTitleLabel)
        bannerTextStackView.addArrangedSubview(bannerDescriptionLabel)

        controlRow.addSubview(selectAllButton)
        controlRow.addSubview(selectAllLabel)
        controlRow.addSubview(sortedButton)

        bannerView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(67)
        }

        bannerIconView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(24)
        }

        bannerTextStackView.snp.makeConstraints {
            $0.leading.equalTo(bannerIconView.snp.trailing).offset(8)
            $0.trailing.equalToSuperview().inset(12)
            $0.top.equalToSuperview().offset(10)
            $0.bottom.equalToSuperview().inset(10)
        }

        controlRow.snp.makeConstraints {
            $0.top.equalTo(bannerView.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(40)
        }

        selectAllButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(24)
        }

        selectAllLabel.snp.makeConstraints {
            $0.leading.equalTo(selectAllButton.snp.trailing).offset(6)
            $0.centerY.equalToSuperview()
        }

        sortedButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(controlRow.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(confirmButton.snp.top).offset(-16)
        }

        confirmButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(safeAreaLayoutGuide).inset(20)
            $0.height.equalTo(44)
        }
    }
}

#Preview {
    let viewController = UIViewController()
    let confirmView = PurchaseConfirmView()

    viewController.view.addSubview(confirmView)
    confirmView.snp.makeConstraints { $0.edges.equalToSuperview() }

    confirmView.applySnapshot(items: [
        PurchaseConfirmItem(
            cartItem: CartItem(
                id: UUID(),
                referenceId: nil,
                name: "토마토",
                mainCategory: "식재료",
                quantity: 8,
                createdAt: Date()
            ),
            isSelected: true
        ),
        PurchaseConfirmItem(
            cartItem: CartItem(
                id: UUID(),
                referenceId: nil,
                name: "바나나",
                mainCategory: "식재료",
                quantity: 3,
                createdAt: Date()
            ),
            isSelected: false
        )
    ])

    return viewController
}
