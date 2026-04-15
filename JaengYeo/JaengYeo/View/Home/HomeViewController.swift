//
//  ViewController.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/2/26.
//

import UIKit

final class HomeViewController: UIViewController {

    private let mainView = HomeView()
    private var dataSource: UICollectionViewDiffableDataSource<HomeSection, Int>?
    
    
    override func loadView() {
        self.view = mainView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configDataSource()
        setSnapshot()
    }
}

extension HomeViewController {
    private func configDataSource() {
        dataSource = UICollectionViewDiffableDataSource(collectionView: mainView.collectionView) { collectionView, indexPath, itemIdentifier in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UnclassifiedCell.id, for: indexPath) as? UnclassifiedCell else { return UICollectionViewCell() }
            cell.config(count: 2)
            return cell
        }
    }
}

extension HomeViewController {
    private func setSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<HomeSection, Int>()
        snapshot.appendSections([.unclassified])
        snapshot.appendItems([0], toSection: .unclassified)
        dataSource?.apply(snapshot, animatingDifferences: false)
    }
}

