//
//  OnboardingViewController.swift
//  JaengYeo
//
//  Created by Codex on 4/23/26.
//

import SnapKit
import Then
import UIKit

protocol OnboardingViewControllerDelegate: AnyObject {
    func didTapOnboardingStartButton()
}

final class OnboardingViewController: BaseViewController {

    //MARK: - Properties
    private let pageCount = 5
    weak var delegate: OnboardingViewControllerDelegate?

    //MARK: - Components
    private let scrollView = UIScrollView().then {
        $0.backgroundColor = .white
        $0.isPagingEnabled = true
        $0.isDirectionalLockEnabled = true
        $0.showsHorizontalScrollIndicator = false
        $0.contentInsetAdjustmentBehavior = .never
    }

    private let contentStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 0
        $0.alignment = .fill
        $0.distribution = .fillEqually
    }

    private let pageControl = UIPageControl().then {
        $0.currentPage = 0
        $0.pageIndicatorTintColor = .gray200
        $0.currentPageIndicatorTintColor = .accent
        $0.numberOfPages = 5
        $0.isUserInteractionEnabled = false
    }

    private let startButton = StyledButton(
        title: "쟁여 시작하기",
        titleConfiguration: .defaultTitle,
        appearanceConfiguration: .defaultAppearance
    )

    //MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bind()
    }
}

//MARK: - Action
private extension OnboardingViewController {
    func updateCurrentPage() {
        let pageWidth = scrollView.bounds.width
        guard pageWidth > 0 else { return }

        let currentPage = Int(round(scrollView.contentOffset.x / pageWidth))
        pageControl.currentPage = max(0, min(pageCount - 1, currentPage))
    }
}

//MARK: - Bind
private extension OnboardingViewController {
    func bind() {
        scrollView.delegate = self
        startButton.addTarget(
            self,
            action: #selector(didTapStartButton),
            for: .touchUpInside
        )
    }
}

//MARK: - UIScrollViewDelegate
extension OnboardingViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCurrentPage()
    }
}

//MARK: - Action
private extension OnboardingViewController {
    @objc
    func didTapStartButton() {
        if let delegate {
            delegate.didTapOnboardingStartButton()
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
}

//MARK: - Configure UI
private extension OnboardingViewController {
    func configureUI() {
        view.backgroundColor = .white

        view.addSubview(scrollView)
        view.addSubview(pageControl)
        view.addSubview(startButton)
        scrollView.addSubview(contentStackView)

        scrollView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(pageControl.snp.top).offset(-12)
        }

        contentStackView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            $0.height.equalTo(scrollView.frameLayoutGuide)
        }

        pageControl.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(startButton.snp.top).offset(-12)
            $0.height.equalTo(20)
        }

        startButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.height.equalTo(44)
        }

        makeStepViews().forEach { stepView in
            let pageScrollView = makePageScrollView(stepView: stepView)
            contentStackView.addArrangedSubview(pageScrollView)

            pageScrollView.snp.makeConstraints {
                $0.width.equalTo(scrollView.frameLayoutGuide)
            }
        }
    }
}

//MARK: - Data
private extension OnboardingViewController {
    func makePageScrollView(stepView: UIView) -> UIScrollView {
        let pageScrollView = UIScrollView().then {
            $0.backgroundColor = .white
            $0.alwaysBounceVertical = true
            $0.showsVerticalScrollIndicator = false
            $0.contentInsetAdjustmentBehavior = .never
            $0.isDirectionalLockEnabled = true
        }

        let contentView = UIView().then {
            $0.backgroundColor = .white
        }

        pageScrollView.addSubview(contentView)
        contentView.addSubview(stepView)

        contentView.snp.makeConstraints {
            $0.edges.equalTo(pageScrollView.contentLayoutGuide)
            $0.width.equalTo(pageScrollView.frameLayoutGuide)
        }

        stepView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        return pageScrollView
    }

    func makeStepViews() -> [UIView] {
        [
            OnboardingFirstView(),
            OnboardingSecondView(),
            OnboardingThirdView(),
            OnboardingFourthView(),
            OnboardingFifthView()
        ]
    }
}

#Preview {
    OnboardingViewController()
}
