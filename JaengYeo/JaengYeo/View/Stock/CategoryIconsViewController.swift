//
//  CategoryIconsViewController.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/15/26.
//

import RxCocoa
import RxSwift
import SnapKit
import UIKit

final class CategoryIconsViewController: UIViewController {

    //MARK: - Properties
    private let iconNames: [String]
    private let disposeBag = DisposeBag()
    private var selectedIconName: String?
    var onApply: ((String) -> Void)?

    //MARK: - Components
    private let mainView = CategoryIconsView()

    //MARK: - Init
    init(
        iconNames: [String],
        selectedIconName: String? = nil
    ) {
        self.iconNames = iconNames
        self.selectedIconName = selectedIconName
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
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
        configureData()
        bind()
        addPanGesture()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateIn()
    }
}

//MARK: - Bind
private extension CategoryIconsViewController {
    func bind() {
        let dimmingTap = UITapGestureRecognizer()
        mainView.dimmingView.addGestureRecognizer(dimmingTap)

        dimmingTap.rx.event
            .bind(onNext: { [weak self] _ in
                guard let self else { return }
                animateOut { self.dismiss(animated: false) }
            })
            .disposed(by: disposeBag)

        mainView.collectionView.rx.itemSelected
            .compactMap { [weak self] indexPath in
                self?.mainView.iconName(at: indexPath)
            }
            .bind(onNext: { [weak self] iconName in
                self?.selectIcon(named: iconName)
            })
            .disposed(by: disposeBag)

        mainView.applyButton.rx.tap
            .bind(onNext: { [weak self] in
                self?.applySelectedIcon()
            })
            .disposed(by: disposeBag)
    }
}

//MARK: - Action
private extension CategoryIconsViewController {
    /// 아이콘 선택
    func selectIcon(named iconName: String) {
        selectedIconName = iconName
    }

    /// 선택 아이콘 적용
    func applySelectedIcon() {
        guard let selectedIconName else { return }

        let iconName = selectedIconName
        animateOut { [weak self] in
            self?.onApply?(iconName)
            self?.dismiss(animated: false)
        }
    }
}

//MARK: - Configure
private extension CategoryIconsViewController {
    /// 데이터 설정
    func configureData() {
        mainView.updateIcons(
            iconNames: iconNames,
            selectedIconName: selectedIconName
        )
    }
}

//MARK: - Animation
private extension CategoryIconsViewController {
    /// 바텀 시트 생성
    func animateIn() {
        view.layoutIfNeeded()
        let contentView = mainView.contentView
        contentView.transform = CGAffineTransform(
            translationX: 0,
            y: contentView.bounds.height + 300
        )

        UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseOut) {
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
private extension CategoryIconsViewController {
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
            contentView.transform = CGAffineTransform(translationX: 0, y: offsetY)

            let ratio = max(0, 1 - (offsetY / contentHeight))
            mainView.dimmingView.alpha = ratio

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
                    self.mainView.dimmingView.alpha = 1
                }
            }

        default:
            break
        }
    }
}
