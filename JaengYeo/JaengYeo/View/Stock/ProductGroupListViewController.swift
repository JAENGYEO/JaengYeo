//
//  ProductGroupListViewController.swift
//  JaengYeo
//
//  Created by Codex on 4/19/26.
//

import RxCocoa
import RxSwift
import UIKit

final class ProductGroupListViewController: BaseViewController {

    //MARK: - ViewModel
    private let viewModel: ProductGroupListViewModel

    //MARK: - Properties
    private let disposeBag = DisposeBag()
    var onSelect: ((UUID) -> Void)?

    //MARK: - Components
    private let mainView = ProductGroupListView()

    //MARK: - Init
    init(viewModel: ProductGroupListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        overrideUserInterfaceStyle = .light
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = mainView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
        addPanGesture()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animateIn()
    }
}

//MARK: - Binding
private extension ProductGroupListViewController {
    func bind() {
        let dimmingTap = UITapGestureRecognizer()
        mainView.dimmingView.addGestureRecognizer(dimmingTap)

        dimmingTap.rx.event
            .bind(onNext: { [weak self] _ in
                self?.close()
            })
            .disposed(by: disposeBag)

        let input = ProductGroupListViewModel.Input(
            viewDidLoad: Observable.just(()),
            itemSelected: mainView.itemSelected
        )

        let output = viewModel.transform(input)

        output.totalCountText
            .bind(onNext: { [weak self] text in
                self?.mainView.titleLabel.text = text
            })
            .disposed(by: disposeBag)

        output.items
            .bind(onNext: { [weak self] items in
                self?.mainView.applySnapshot(with: items)
            })
            .disposed(by: disposeBag)

        output.selectedProductID
            .bind(onNext: { [weak self] productID in
                self?.selectProduct(productID)
            })
            .disposed(by: disposeBag)
    }
}

//MARK: - Action
private extension ProductGroupListViewController {
    /// 상품 선택
    func selectProduct(_ productID: UUID) {
        animateOut { [weak self] in
            self?.dismiss(animated: false) {
                self?.onSelect?(productID)
            }
        }
    }

    /// 화면 닫기
    func close() {
        animateOut { [weak self] in
            self?.dismiss(animated: false)
        }
    }
}

//MARK: - Animation
private extension ProductGroupListViewController {
    /// 바텀 시트 생성
    func animateIn() {
        view.layoutIfNeeded()
        let contentView = mainView.contentView
        contentView.transform = CGAffineTransform(
            translationX: 0,
            y: contentView.bounds.height + 300
        )

        UIView.animate(
            withDuration: 0.35,
            delay: 0,
            options: .curveEaseOut
        ) {
            self.mainView.dimmingView.alpha = 1
            contentView.transform = .identity
        }
    }

    /// 바텀 시트 소멸
    func animateOut(completion: @escaping () -> Void) {
        view.layoutIfNeeded()
        let contentView = mainView.contentView

        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            options: .curveEaseIn,
            animations: {
                self.mainView.dimmingView.alpha = 0
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
}

//MARK: - Pan Gesture
private extension ProductGroupListViewController {
    /// contentView에 pan gesture 추가
    func addPanGesture() {
        let pan = UIPanGestureRecognizer(
            target: self,
            action: #selector(handlePan(_:))
        )
        pan.cancelsTouchesInView = false
        mainView.contentView.addGestureRecognizer(pan)
    }

    /// gesture 상태에 따라 drag dismiss 적용
    @objc
    func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: mainView.contentView)
        let velocity = gesture.velocity(in: mainView.contentView)
        let contentView = mainView.contentView
        let contentHeight = contentView.bounds.height

        switch gesture.state {
        case .changed:
            let offsetY = max(0, translation.y)
            contentView.transform = CGAffineTransform(
                translationX: 0,
                y: offsetY
            )
            mainView.dimmingView.alpha = max(0, 1 - offsetY / contentHeight)

        case .ended, .cancelled:
            let offsetY = max(0, translation.y)
            let shouldDismiss = offsetY > contentHeight * 0.35 || velocity.y > 800

            if shouldDismiss {
                close()
            } else {
                UIView.animate(
                    withDuration: 0.3,
                    delay: 0,
                    usingSpringWithDamping: 0.8,
                    initialSpringVelocity: 0.5
                ) {
                    contentView.transform = .identity
                    self.mainView.dimmingView.alpha = 1
                }
            }

        default:
            break
        }
    }
}
