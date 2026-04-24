//
//  CategorySelectionViewController.swift
//  JaengYeo
//
//  Created by Codex on 4/12/26.
//

import RxCocoa
import RxRelay
import RxSwift
import SnapKit
import Then
import UIKit

final class CategorySelectionViewController: BaseViewController {

    //MARK: - Enum
    private enum Section {
        case main
    }

    //MARK: - ViewModel
    private let viewModel: CategorySelectionViewModel

    //MARK: - Properties
    private let disposeBag = DisposeBag()
    /// 페이지당 아이템 개수
    private let itemsPerPage = 15
    private lazy var dataSource = configureDataSource()
    /// 적용 결과 전달
    var onApply: (([String]) -> Void)?

    //MARK: - Components
    /// 카테고리 선택 뷰
    private let categorySelectionView = CategorySelectionView()

    //MARK: - Init
    init(items: [CategorySelectionItem] = []) {
        self.viewModel = CategorySelectionViewModel(items: items)
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        overrideUserInterfaceStyle = .light
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
        addPanGesture()
    }

    override func loadView() {
        self.view = categorySelectionView
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animateIn()
    }
}

//MARK: - Binding
extension CategorySelectionViewController {
    fileprivate func bind() {
        let itemSelectionToggledRelay = PublishRelay<CategorySelectionItem>()
        
        let dimmingTap = UITapGestureRecognizer()
        categorySelectionView.dimmingView.addGestureRecognizer(dimmingTap)
        
        dimmingTap.rx.event
            .bind(onNext: { [weak self] _ in
                guard let self else { return }
                animateOut { self.dismiss(animated: false) }
            })
            .disposed(by: disposeBag)
        
        /// 아이템 선택 이벤트
        categorySelectionView.collectionView.rx.itemSelected
            .do(onNext: { [weak self] indexPath in
                self?.categorySelectionView.collectionView.deselectItem(
                    at: indexPath,
                    animated: false
                )
            })
            .compactMap { [weak self] indexPath in
                self?.dataSource.itemIdentifier(for: indexPath)
            }
            .bind(to: itemSelectionToggledRelay)
            .disposed(by: disposeBag)
        
        /// 페이지 변경 이벤트
        categorySelectionView.collectionView.rx.contentOffset
            .compactMap { [weak self] contentOffset -> Int? in
                let collectionView = self?.categorySelectionView.collectionView
                guard let collectionView, collectionView.bounds.width > 0 else {
                    return nil
                }
                return Int(round(contentOffset.x / collectionView.bounds.width))
            }
            .distinctUntilChanged()
            .bind(onNext: { [weak self] page in
                self?.categorySelectionView.pageControl.currentPage = page
            })
            .disposed(by: disposeBag)
        
        /// 페이지 컨트롤 이벤트
        categorySelectionView.pageControl.rx.controlEvent(.valueChanged)
            .bind(onNext: { [weak self] in
                guard let self else { return }
                self.categorySelectionView.scrollToPage(
                    self.categorySelectionView.pageControl.currentPage
                )
            })
            .disposed(by: disposeBag)
        
        /// ViewModel 입력값
        let input = CategorySelectionViewModel.Input(
            itemSelectionToggled: itemSelectionToggledRelay.asObservable(),
            resetTapped: categorySelectionView.resetButton.rx.tap
                .asObservable(),
            applyTapped: categorySelectionView.applyButton.rx.tap.asObservable()
        )
        
        let output = viewModel.transform(input)
        
        /// 아이템 목록 바인딩
        output.items
            .bind(onNext: { [weak self] items in
                guard let self else { return }
                self.categorySelectionView.configurePageControl(
                    itemCount: items.count,
                    itemsPerPage: self.itemsPerPage
                )
                self.applySnapshot(with: items)
            })
            .disposed(by: disposeBag)
        
        /// 적용 버튼 타이틀 바인딩
        output.applyButtonTitle
            .bind(onNext: { [weak self] title in
                guard let self else { return }
                self.categorySelectionView.applyButton.updateTitle(title)
            })
            .disposed(by: disposeBag)
        
        /// 적용 결과 바인딩
        output.appliedItemIDs
            .bind(onNext: { [weak self] selectedItemIDs in
                guard let self else { return }
                animateOut {
                    self.onApply?(selectedItemIDs)
                    self.dismiss(animated: false)
                }
            })
            .disposed(by: disposeBag)
    }
}

//MARK: - Action
extension CategorySelectionViewController {
    fileprivate func animateIn() {
        view.layoutIfNeeded()
        let contentView = categorySelectionView.contentView
        contentView.transform = CGAffineTransform(
            translationX: 0,
            y: contentView.bounds.height + 300
        )

        UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseOut) {
            self.categorySelectionView.dimmingView.alpha = 1
            contentView.transform = .identity
        }
    }

    fileprivate func animateOut(completion: @escaping () -> Void) {
        let contentView = categorySelectionView.contentView

        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            options: .curveEaseIn,
            animations: {
                self.categorySelectionView.dimmingView.alpha = 0
                contentView.transform = CGAffineTransform(
                    translationX: 0,
                    y: contentView.bounds.height + 300
                )
            },
            completion: { _ in
                completion()
            }
        )
    }

    fileprivate func addPanGesture() {
        let pan = UIPanGestureRecognizer(
            target: self,
            action: #selector(handlePan(_:))
        )
        pan.cancelsTouchesInView = false
        categorySelectionView.contentView.addGestureRecognizer(pan)
    }

    @objc
    fileprivate func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(
            in: categorySelectionView.contentView
        )
        let velocity = gesture.velocity(in: categorySelectionView.contentView)
        let contentView = categorySelectionView.contentView
        let contentHeight = contentView.bounds.height

        switch gesture.state {
        case .changed:
            let offsetY = max(0, translation.y)
            contentView.transform = CGAffineTransform(
                translationX: 0,
                y: offsetY
            )

            let ratio = max(0, 1 - (offsetY / contentHeight))
            categorySelectionView.dimmingView.alpha = ratio

        case .ended, .cancelled:
            if translation.y > contentHeight * 0.35 || velocity.y > 800 {
                animateOut { self.dismiss(animated: false) }
            } else {
                UIView.animate(
                    withDuration: 0.3,
                    delay: 0,
                    usingSpringWithDamping: 0.8,
                    initialSpringVelocity: 0.5
                ) {
                    contentView.transform = .identity
                    self.categorySelectionView.dimmingView.alpha = 1
                }
            }
        default:
            break
        }
    }
}

//MARK: - DataSource
extension CategorySelectionViewController {
    /// 데이터소스 설정
    private func configureDataSource() -> UICollectionViewDiffableDataSource<
        Section, CategorySelectionItem
    > {
        let cellCategory = UICollectionView.CellRegistration<
            CategorySelectionItemCell, CategorySelectionItem
        > {
            cell,
            indexPath,
            item in
            cell.updateUI(
                title: item.title,
                image: item.image,
                isSelect: item.isSelect,
                isEnabled: item.isEnabled
            )
        }

        return UICollectionViewDiffableDataSource<
            Section, CategorySelectionItem
        >(
            collectionView: categorySelectionView.collectionView
        ) { collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(
                using: cellCategory,
                for: indexPath,
                item: item
            )
        }
    }

    /// 스냅샷 적용
    func applySnapshot(with datas: [CategorySelectionItem]) {
        var snapshot = NSDiffableDataSourceSnapshot<
            Section, CategorySelectionItem
        >()
        snapshot.appendSections([.main])
        snapshot.appendItems(datas, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}


#Preview {
    CategorySelectionViewController(
        items: (1...20).map {
            CategorySelectionItem(
                id: "\($0)",
                title: "항목\($0)",
                image: UIImage(named: "categoryIcon"),
                isSelect: false
            )
        }
    )
}
