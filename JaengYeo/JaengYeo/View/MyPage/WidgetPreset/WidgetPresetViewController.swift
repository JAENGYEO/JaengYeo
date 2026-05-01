//
//  WidgetPresetViewController.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/30/26.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import Then

final class WidgetPresetViewController: BaseViewController {
    private let viewModel: WidgetPresetViewModel
    private let mainView = WidgetPresetView()
    private let disposeBag = DisposeBag()
    
    private let addButton = UIBarButtonItem(
        image: UIImage(systemName: "plus"),
        style: .plain,
        target: nil,
        action: nil
    )
    private lazy var dataSource = makeDataSource()
    
    init(viewModel: WidgetPresetViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = mainView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mainView.emptyPresetView.config(
            title: "등록된 프리셋이 없어요",
            description: "프리셋을 등록해서 위젯을 만들어보세요!"
        )
        configNavigationBar()
        bind()
    }
}

extension WidgetPresetViewController {
    private func configNavigationBar() {
        title = "위젯 설정"
        navigationItem.rightBarButtonItem = addButton
        addButton.tintColor = .gray800
    }
}

extension WidgetPresetViewController {
    private func bind() {
        let viewWillAppear = rx.methodInvoked(#selector(viewWillAppear(_:)))
            .map { _ in }
        
        let itemSelected = mainView.collectionView.rx.itemSelected
            .compactMap { [weak self] indexPath -> UUID? in
                guard let summary = self?.dataSource.itemIdentifier(for: indexPath) else { return nil }
                return summary.id
            }
            .asObservable()
        
        let input = WidgetPresetViewModel.Input(
            viewWillAppear: viewWillAppear,
            itemSelected: itemSelected,
            addButtonTapped: addButton.rx.tap.asObservable()
        )
        let output = viewModel.transform(input)
        output.presets
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] presets in
                self?.mainView.emptyPresetView.isHidden = !presets.isEmpty
                self?.applySnapshot(presets: presets)
            })
            .disposed(by: disposeBag)
        output.canAddMore
            .observe(on: MainScheduler.instance)
            .bind(to: addButton.rx.isEnabled)
            .disposed(by: disposeBag)
    }
}

extension WidgetPresetViewController {
    private func makeDataSource() -> UICollectionViewDiffableDataSource<WidgetPresetSection, WidgetPresetViewModel.PresetSummary> {
        UICollectionViewDiffableDataSource(collectionView: mainView.collectionView) { collectionView, indexPath, itemIdentifier in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: WidgetPresetCell.id, for: indexPath) as? WidgetPresetCell else {
                return UICollectionViewCell()
            }
            cell.config(title: itemIdentifier.name, count: itemIdentifier.productCount)
            return cell
        }
    }
    
    private func applySnapshot(presets: [WidgetPresetViewModel.PresetSummary]) {
        var snapshot = NSDiffableDataSourceSnapshot<WidgetPresetSection, WidgetPresetViewModel.PresetSummary>()
        snapshot.appendSections([.main])
        snapshot.appendItems(presets, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}
