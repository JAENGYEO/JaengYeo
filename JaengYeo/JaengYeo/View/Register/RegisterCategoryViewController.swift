//
//  RegisterCategoryViewController.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/14/26.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

final class RegisterCategoryViewController: UIViewController {
    
    // MARK: Properties
    private enum Section { case main }
    
    private let disposeBag = DisposeBag()
    private let itemsPerPage = 15
    private lazy var dataSource = configureDataSource()
    
    private var items: [CategorySelectionItem]
    private var selectedID: String?
    
    var onSelect: ((String?) -> Void)?
    
    // MARK: Components
    private let mainView = RegisterCategoryView()
    
    // MARK: Init
    init(items: [CategorySelectionItem], selectedID: String? = nil) {
        self.items = items
        self.selectedID = selectedID
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        applySnapshot()
        bind()
        addPanGesture()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.layoutIfNeeded()
        animateIn()
    }
}

// MARK: Bind
extension RegisterCategoryViewController {
    private func bind() {
        // 셀 선택 — 단일 선택 토글
        mainView.collectionView.rx.itemSelected
            .do(onNext: { [weak self] indexPath in
                self?.mainView.collectionView.deselectItem(at: indexPath, animated: false)
            })
            .compactMap { [weak self] indexPath in
                self?.dataSource.itemIdentifier(for: indexPath)
            }
            .bind(onNext: { [weak self] item in
                guard let self else { return }
                selectedID = selectedID == item.id ? nil : item.id
                applySnapshot()
            })
            .disposed(by: disposeBag)
        
        // 페이지 변경
        mainView.collectionView.rx.contentOffset
            .compactMap { [weak self] offset -> Int? in
                guard let self,
                      mainView.collectionView.bounds.width > 0 else { return nil }
                return Int(round(offset.x / mainView.collectionView.bounds.width))
            }
            .distinctUntilChanged()
            .bind(onNext: { [weak self] page in
                self?.mainView.pageControl.currentPage = page
            })
            .disposed(by: disposeBag)
        
        // 페이지 컨트롤
        mainView.pageControl.rx.controlEvent(.valueChanged)
            .bind(onNext: { [weak self] in
                guard let self else { return }
                mainView.scrollToPage(mainView.pageControl.currentPage)
            })
            .disposed(by: disposeBag)
        
        // 완료 버튼
        mainView.confirmButton.rx.tap
            .bind(onNext: { [weak self] in
                guard let self else { return }
                onSelect?(selectedID)
                animateOut { self.dismiss(animated: false) }
            })
            .disposed(by: disposeBag)
        
        // 딤 뷰 탭 → 취소 (선택 없이 dismiss)
        let dimTap = UITapGestureRecognizer()
        mainView.dimmingView.addGestureRecognizer(dimTap)
        dimTap.rx.event
            .bind(onNext: { [weak self] _ in
                self?.animateOut { self?.dismiss(animated: false) }
            })
            .disposed(by: disposeBag)
    }
}

// MARK: DataSource
extension RegisterCategoryViewController {
    private func configureDataSource() -> UICollectionViewDiffableDataSource<Section, CategorySelectionItem> {
        let cellRegistration = UICollectionView.CellRegistration<CategorySelectionItemCell, CategorySelectionItem> { cell, _, item in
            cell.updateUI(title: item.title, image: item.image, isSelect: item.isSelect)
        }
        return UICollectionViewDiffableDataSource(
            collectionView: mainView.collectionView
        ) { collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
    }
    
    private func applySnapshot() {
        let updatedItems = items.map {
            CategorySelectionItem(
                id: $0.id,
                title: $0.title,
                image: $0.image,
                isSelect: $0.id == selectedID
            )
        }
        mainView.configurePageControl(itemCount: updatedItems.count, itemsPerPage: itemsPerPage)
        var snapshot = NSDiffableDataSourceSnapshot<Section, CategorySelectionItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(updatedItems)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

// MARK: Animation
extension RegisterCategoryViewController {
    private func animateIn() {
        let contentView = mainView.contentView
        contentView.transform = CGAffineTransform(translationX: 0, y: contentView.bounds.height + 300)
        UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseOut) {
            self.mainView.dimmingView.alpha = 1
            contentView.transform = .identity
        }
    }

    private func animateOut(completion: @escaping () -> Void) {
        let contentView = mainView.contentView
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
            self.mainView.dimmingView.alpha = 0
            contentView.transform = CGAffineTransform(translationX: 0, y: contentView.bounds.height + 300)
        }, completion: { _ in completion() })
    }
}

// MARK: Pan Gesture
extension RegisterCategoryViewController {
    private func addPanGesture() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.cancelsTouchesInView = false
        mainView.contentView.addGestureRecognizer(pan)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: mainView.contentView)
        let velocity = gesture.velocity(in: mainView.contentView)
        let contentView = mainView.contentView
        let contentHeight = contentView.bounds.height

        switch gesture.state {
        case .changed:
            let offsetY = max(0, translation.y)
            contentView.transform = CGAffineTransform(translationX: 0, y: offsetY)
            mainView.dimmingView.alpha = max(0, 1 - (offsetY / contentHeight))
        case .ended, .cancelled:
            if translation.y > contentHeight * 0.35 || velocity.y > 800 {
                animateOut { self.dismiss(animated: false) }
            } else {
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
                    contentView.transform = .identity
                    self.mainView.dimmingView.alpha = 1
                }
            }
        default:
            break
        }
    }
}

// MARK: Configure UI
extension RegisterCategoryViewController {
    private func configureUI() {
        view.backgroundColor = .clear
        view.addSubview(mainView)
        
        mainView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}
