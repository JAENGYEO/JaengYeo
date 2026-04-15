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
    private var dataSource: UICollectionViewDiffableDataSource<HomeSection, Int>?
    
    private let viewWillAppearRelay = PublishRelay<Void>()
    
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
        let input = HomeViewModel.Input(
            viewWillAppear: viewWillAppearRelay.asObservable(),
            unclassifiedTapped: mainView.collectionView.rx.itemSelected
                .filter { $0.section == HomeSection.unclassified.rawValue }
                .map { _ in }
        )
        let output = viewModel.transform(input)
        
        output.unclassifiedCount
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] count in
                self?.setSnapshot(unclassifiedCount: count)
            })
            .disposed(by: disposeBag)
    }
}

extension HomeViewController {
    private func configDataSource() {
        dataSource = UICollectionViewDiffableDataSource(collectionView: mainView.collectionView) { collectionView, indexPath, itemIdentifier in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UnclassifiedCell.id, for: indexPath) as? UnclassifiedCell else { return UICollectionViewCell() }
            cell.config(count: itemIdentifier)
            return cell
        }
    }
}

extension HomeViewController {
    private func setSnapshot(unclassifiedCount: Int) {
        var snapshot = NSDiffableDataSourceSnapshot<HomeSection, Int>()
        if unclassifiedCount > 0 {
            snapshot.appendSections([.unclassified])
            snapshot.appendItems([unclassifiedCount], toSection: .unclassified)
        }
        dataSource?.apply(snapshot, animatingDifferences: false)
    }
}

