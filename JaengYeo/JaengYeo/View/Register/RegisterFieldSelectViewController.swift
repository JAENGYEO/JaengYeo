//
//  RegisterFieldSelectViewController.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/12/26.
//

import UIKit
import RxSwift
import RxCocoa

protocol RegisterFieldSelectViewControllerDelegate: AnyObject {
    func didSelect(fields: Set<RegisterOptionField>)
}

final class RegisterFieldSelectViewController: UIViewController {

    weak var delegate: RegisterFieldSelectViewControllerDelegate?

    private let mainView = RegisterFieldSelectView()
    private let disposeBag = DisposeBag()
    private var selectedFields: Set<RegisterOptionField>

    init(selectedFields: Set<RegisterOptionField> = []) {
        self.selectedFields = selectedFields
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = mainView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configFieldRows()
        bind()
        addPanGesture()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animateIn()
    }
}

extension RegisterFieldSelectViewController {
    private func bind() {
        let dimmingTap = UITapGestureRecognizer()
        mainView.dimmingView.addGestureRecognizer(dimmingTap)
        dimmingTap.rx.event
            .bind(onNext: { [weak self] _ in
                guard let self else { return }
                animateOut { self.dismiss(animated: false) }
            })
            .disposed(by: disposeBag)

        mainView.resetButton.rx.tap
            .bind(onNext: { [weak self] in
                guard let self else { return }
                selectedFields.removeAll()
                let symbolConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
                mainView.fieldStackView.arrangedSubviews.forEach { row in
                    row.subviews.compactMap { $0 as? UIImageView }.first?.image = UIImage(systemName: "circle.fill", withConfiguration: symbolConfig)
                    row.subviews.compactMap { $0 as? UIImageView }.first?.tintColor = .gray50
                    row.subviews.compactMap { $0 as? UIImageView }.first?.layer.borderWidth = 1
                }
            })
            .disposed(by: disposeBag)

        mainView.confirmButton.rx.tap
            .bind(onNext: { [weak self] in
                guard let self else { return }
                let fields = selectedFields
                animateOut {
                    self.delegate?.didSelect(fields: fields)
                    self.dismiss(animated: false)
                }
            })
            .disposed(by: disposeBag)
    }
}

// MARK: Field Rows
extension RegisterFieldSelectViewController {
    private func configFieldRows() {
        RegisterOptionField.allCases.forEach { field in
            let isSelected = selectedFields.contains(field)
            let row = mainView.makeFieldRow(field: field, isSelected: isSelected)

            let tapGesture = UITapGestureRecognizer()
            row.addGestureRecognizer(tapGesture)
            tapGesture.rx.event
                .bind(onNext: { [weak self, weak row] _ in
                    guard let self, let row else { return }
                    if selectedFields.contains(field) {
                        selectedFields.remove(field)
                    } else {
                        selectedFields.insert(field)
                    }
                    let isSelected = selectedFields.contains(field)
                    let symbolConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
                    if let indicator = row.subviews.compactMap({ $0 as? UIImageView }).first {
                        indicator.image = isSelected
                            ? UIImage(systemName: "checkmark.circle.fill", withConfiguration: symbolConfig)
                            : UIImage(systemName: "circle.fill", withConfiguration: symbolConfig)
                        indicator.tintColor = isSelected ? .accent : .gray50
                        indicator.layer.borderWidth = isSelected ? 0 : 1
                    }
                })
                .disposed(by: disposeBag)
            mainView.fieldStackView.addArrangedSubview(row)
        }
    }
}

// MARK: Animation
extension RegisterFieldSelectViewController {
    // 바텀 시트 생성
    private func animateIn() {
        let contentView = mainView.contentView
        contentView.transform = CGAffineTransform(translationX: 0, y: contentView.bounds.height + 300)

        UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseOut) {
            self.mainView.dimmingView.alpha = 1
            contentView.transform = .identity
        }
    }

    // 소멸
    private func animateOut(completion: @escaping () -> Void) {
        let contentView = mainView.contentView

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
            self.mainView.dimmingView.alpha = 0
            contentView.transform = CGAffineTransform(translationX: 0, y: contentView.bounds.height + 300)
        }, completion: { _ in
            completion()
        })
    }
}

// MARK: Pan Gesture
extension RegisterFieldSelectViewController {
    // contentView에 gesture 주입
    private func addPanGesture() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.cancelsTouchesInView = false
        mainView.contentView.addGestureRecognizer(pan)
    }

    // getsture 상태에 따라 드래그 적용
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
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
                    withDuration: 0.3, delay: 0,
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
