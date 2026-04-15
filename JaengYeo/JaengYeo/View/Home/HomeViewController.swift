//
//  ViewController.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/2/26.
//

import UIKit
import RxSwift
import RxCocoa

final class HomeViewController: UIViewController {

    private let disposeBag = DisposeBag()
    private let viewModel: HomeViewModel
    
    private let mainView = HomeView()
    private var dataSource: UICollectionViewDiffableDataSource<HomeSection, HomeItem>?
    
    private let viewWillAppearRelay = PublishRelay<Void>()
    
    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        overrideUserInterfaceStyle = .light
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = mainView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configDataSource()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearRelay.accept(())
    }
}

extension HomeViewController {
    private func bind() {
        
        let categoryCardTapped = mainView.collectionView.rx.itemSelected
            .filter { $0.section == HomeSection.categorySummary.rawValue }
            .compactMap { [weak self] indexPath -> String? in
                guard case .categorySummary(let summary) = self?.dataSource?.itemIdentifier(for: indexPath) else { return nil }
                return summary.name
            }
            .asObservable()
        
        let input = HomeViewModel.Input(
            viewWillAppear: viewWillAppearRelay.asObservable(),
            unclassifiedTapped: mainView.collectionView.rx.itemSelected
                .filter { $0.section == HomeSection.unclassified.rawValue }
                .map { _ in },
            categoryCardTapped: categoryCardTapped
        )
        let output = viewModel.transform(input)
        
        Observable.combineLatest(output.unclassifiedCount, output.categorySummaries, output.statusAlerts)
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] count, summaries, alerts in
                self?.setSnapshot(unclassifiedCount: count, categorySummaries: summaries, statusAlerts: alerts)
            })
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
            }
        }
        dataSource?.supplementaryViewProvider = { collectionView, kind, indexPath in
            guard kind == UICollectionView.elementKindSectionHeader,
                  let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: HomeSectionHeaderView.id, for: indexPath) as? HomeSectionHeaderView else { return UICollectionReusableView() }
            header.config(title: HomeSection(rawValue: indexPath.section)?.title ?? "")
            return header
        }
    }
}

extension HomeViewController {
    private func setSnapshot(unclassifiedCount: Int, categorySummaries: [HomeViewModel.CategorySummary], statusAlerts: [HomeViewModel.StatusSummary]) {
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
        dataSource?.apply(snapshot, animatingDifferences: false)
    }
}

