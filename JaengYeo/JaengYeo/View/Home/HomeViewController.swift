//
//  ViewController.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/2/26.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

protocol HomeViewControllerDelegate: AnyObject {
    func didTapMyPageButton()
}

final class HomeViewController: BaseViewController {

    private let disposeBag = DisposeBag()
    private let viewModel: HomeViewModel
    weak var delegate: HomeViewControllerDelegate?
    
    private let mainView = HomeView()
    private var dataSource: UICollectionViewDiffableDataSource<HomeSection, HomeItem>?
    
    private let viewWillAppearRelay = PublishRelay<Void>()
    private let recentItemQuantityIncreasedRelay = PublishRelay<UUID>()
    private let recentItemQuantityDecreasedRelay = PublishRelay<UUID>()
    private let recentItemDeletedRelay = PublishRelay<[UUID]>()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    private let logoImage = UIImageView(image: UIImage(named: "homeLogo")).then {
        $0.contentMode = .scaleAspectFit
    }
        
    
    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = mainView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configDataSource()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearRelay.accept(())
        logoImage.isHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        logoImage.isHidden = true
    }
}

extension HomeViewController {
    private func configureNavigationBar() {

        navigationController?.navigationBar.addSubview(logoImage)
        logoImage.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.top.equalToSuperview().offset(8)
            $0.width.equalTo(92)
            $0.height.equalTo(44)
        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "mypage02Icon"),
            primaryAction: UIAction { [weak self] _ in
                self?.delegate?.didTapMyPageButton()
            }
        )
    }
}

extension HomeViewController {
    private func bind() {
        let categoryCardTapped = mainView.collectionView.rx.itemSelected
            .filter { [weak self] indexPath in
                self?.dataSource?.sectionIdentifier(for: indexPath.section) == .categorySummary
            }
            .compactMap { [weak self] indexPath -> String? in
                guard case .categorySummary(let summary) = self?.dataSource?.itemIdentifier(for: indexPath) else { return nil }
                return summary.name
            }
            .asObservable()
        
        let statusAlertTapped = mainView.collectionView.rx.itemSelected
            .filter { [weak self] indexPath in
                self?.dataSource?.sectionIdentifier(for: indexPath.section) == .statusAlert
            }
            .compactMap { [weak self] indexPath -> HomeViewModel.AlertType? in
                guard case .statusAlert(let summary) = self?.dataSource?.itemIdentifier(for: indexPath) else { return nil }
                return summary.type
            }
            .asObservable()
        
        let recentItemTapped = mainView.collectionView.rx.itemSelected
            .filter { [weak self] indexPath in
                self?.dataSource?.sectionIdentifier(for: indexPath.section) == .recentItems
            }
            .compactMap { [weak self] indexPath -> UUID? in
                guard case .recentItem(let summary) = self?.dataSource?.itemIdentifier(for: indexPath) else { return nil }
                return summary.id
            }
            .asObservable()
        
        let input = HomeViewModel.Input(
            viewWillAppear: viewWillAppearRelay.asObservable(),
            unclassifiedTapped: mainView.collectionView.rx.itemSelected
                .filter { [weak self] indexPath in
                    self?.dataSource?.sectionIdentifier(for: indexPath.section) == .unclassified
                }
                .map { _ in },
            categoryCardTapped: categoryCardTapped,
            statusAlertTapped: statusAlertTapped,
            recentItemTapped: recentItemTapped,
            recentItemQuantityIncreased: recentItemQuantityIncreasedRelay.asObservable(),
            recentItemQuantityDecreased: recentItemQuantityDecreasedRelay.asObservable(),
            recentItemDeleted: recentItemDeletedRelay.asObservable()
        )
        let output = viewModel.transform(input)
        
        Observable.combineLatest(output.unclassifiedCount, output.categorySummaries, output.statusAlerts, output.recentItems)
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] count, summaries, alerts, recents in
                let isEmpty = count == 0 && summaries.isEmpty && alerts.isEmpty && recents.isEmpty
                self?.mainView.emptyStateView.isHidden = !isEmpty
                self?.mainView.collectionView.isHidden = isEmpty
                self?.setSnapshot(unclassifiedCount: count, categorySummaries: summaries, statusAlerts: alerts, recentItems: recents)
            })
            .disposed(by: disposeBag)
        
        mainView.emptyStateView.actionButton.rx.tap
            .bind(to: viewModel.navigateToRegister)
            .disposed(by: disposeBag)
    }
}

extension HomeViewController {
    private func configDataSource() {
        dataSource = UICollectionViewDiffableDataSource(collectionView: mainView.collectionView) { collectionView, indexPath, itemIdentifier in
            switch itemIdentifier {
            case .unclassified(let count):
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UnclassifiedCell.id, for: indexPath) as? UnclassifiedCell else { return UICollectionViewCell() }
                cell.config(count: count)
                return cell
            case .categorySummary(let summary):
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategorySummaryCell.id, for: indexPath) as? CategorySummaryCell else { return UICollectionViewCell() }
                cell.config(name: summary.name, totalCount: summary.totalCount, midCount: summary.midCategoryCount, subCount: summary.subCategoryCount)
                return cell
            case .statusAlert(let summary):
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StatusAlertCell.id, for: indexPath) as? StatusAlertCell else { return UICollectionViewCell() }
                let isExpiry = summary.type == .expiry
                cell.config(
                    title: isExpiry ? "유통기한 임박" : "재고 부족",
                    count: summary.imminentCount,
                    ratio: summary.ratio,
                    color: isExpiry ? .primaryRed : .primaryOrange,
                    icon: isExpiry ? "timeIcon" : "bagIcon"
                )
                return cell
            case .recentItem(let summary):
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProductCell.id, for: indexPath) as? ProductCell else { return UICollectionViewCell() }
                var descriptions = [summary.mainCategory]
                if let midCategory = summary.midCategoryName { descriptions.append(midCategory) }
                descriptions.append(self.dateFormatter.string(from: summary.createdAt))
                cell.updateUI(
                    type: .homeType,
                    title: summary.name,
                    freshness: nil,
                    descriptions: descriptions,
                    subdescriptions: nil,
                    count: summary.quantity,
                    image: summary.image ?? summary.subCategoryIconName.flatMap { UIImage(named: $0) } //TODO: 추후에 수정 필요
                )

                cell.bindAddButtonTap { [weak self] in
                    self?.recentItemQuantityIncreasedRelay.accept(summary.id)
                }

                cell.bindDeleteButtonTap { [weak self] in
                    guard let self else { return }

                    self.makeRecentItemDecreaseAction(summary: summary)
                        .bind(onNext: { productIDs in
                            if summary.quantity == 1 {
                                self.recentItemDeletedRelay.accept(productIDs)
                            } else {
                                self.recentItemQuantityDecreasedRelay.accept(summary.id)
                            }
                        })
                        .disposed(by: self.disposeBag)
                }
                return cell
            }
        }
        dataSource?.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard kind == UICollectionView.elementKindSectionHeader,
                  let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: HomeSectionHeaderView.id, for: indexPath) as? HomeSectionHeaderView else { return UICollectionReusableView() }
            header.config(title: self?.dataSource?.sectionIdentifier(for: indexPath.section)?.title ?? "")
            return header
        }
    }
}

//MARK: - Action
private extension HomeViewController {
    /// 최근 등록 상품 재고 차감 액션 생성
    func makeRecentItemDecreaseAction(
        summary: HomeViewModel.RecentItemSummary
    ) -> Observable<[UUID]> {
        guard summary.quantity == 1 else {
            return .just([summary.id])
        }

        return AlertController.rx.alert(
            on: self,
            image: UIImage(named: "alertRed") ?? UIImage(),
            title: "재고 차감",
            message: "재고가 0이 되면 상품은 삭제됩니다.\n삭제하시겠습니까?",
            actions: [
                .cancel("취소"),
                .destructive("삭제")
            ]
        )
        .filter { $0.title == "삭제" }
        .map { _ in [summary.id] }
        .asObservable()
    }
}

extension HomeViewController {
    private func setSnapshot(unclassifiedCount: Int, categorySummaries: [HomeViewModel.CategorySummary], statusAlerts: [HomeViewModel.StatusSummary], recentItems: [HomeViewModel.RecentItemSummary]) {
        var snapshot = NSDiffableDataSourceSnapshot<HomeSection, HomeItem>()
        if unclassifiedCount > 0 {
            snapshot.appendSections([.unclassified])
            snapshot.appendItems([.unclassified(unclassifiedCount)], toSection: .unclassified)
        }
        if !categorySummaries.isEmpty {
            snapshot.appendSections([.categorySummary])
            snapshot.appendItems(categorySummaries.map { .categorySummary($0) }, toSection: .categorySummary)
        }
        
        if !statusAlerts.isEmpty {
            snapshot.appendSections([.statusAlert])
            snapshot.appendItems(statusAlerts.map { .statusAlert($0)}, toSection: .statusAlert)
        }
        
        if !recentItems.isEmpty {
            snapshot.appendSections([.recentItems])
            snapshot.appendItems(recentItems.map { .recentItem($0) }, toSection:  .recentItems)
        }
        mainView.sections = snapshot.sectionIdentifiers
        dataSource?.apply(snapshot, animatingDifferences: false)
    }
}
