//
//  AlertController.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/13/26.
//

import UIKit
import Then
import SnapKit

final class AlertController: UIViewController {
  private let alertTransitioningDelegate = AlertTransitioningDelegate()

  private let actions: [Action]
  private let contentView: ContentView

  init(image: UIImage, title: String, message: String, actions: [Action]) {
    self.actions = actions
    self.contentView = ContentView(image: image, title: title, message: message, actions: actions)
    super.init(nibName: nil, bundle: nil)
    self.transitioningDelegate = alertTransitioningDelegate
    self.modalPresentationStyle = .custom
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.addSubview(contentView)
    contentView.snp.makeConstraints {
      $0.top.greaterThanOrEqualTo(view.safeAreaLayoutGuide).priority(.high)
      $0.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide).priority(.high)
      $0.center.equalToSuperview()
      $0.width.equalTo(310)
    }

    for (button, action) in zip(contentView.buttons, actions) {
      let buttonAction = UIAction { [weak self] _ in
        self?.dismiss(animated: true) {
          action.handler(action)
        }
      }
      button.addAction(buttonAction, for: .primaryActionTriggered)
    }
  }
}

extension AlertController {
  struct Action {
    let title: String
    let style: ActionStyle
    let handler: (Action) -> Void

    @inlinable static func `default`(_ title: String, handler: @escaping (Action) -> Void = { _ in }) -> Action {
      Action(title: title, style: .default, handler: handler)
    }

    @inlinable static func destructive(_ title: String, handler: @escaping (Action) -> Void = { _ in }) -> Action {
      Action(title: title, style: .destructive, handler: handler)
    }

    @inlinable static func cancel(_ title: String, handler: @escaping (Action) -> Void = { _ in }) -> Action {
      Action(title: title, style: .cancel, handler: handler)
    }
  }
}

extension AlertController {
  enum ActionStyle {
    case `default`
    case destructive
    case cancel
  }
}

extension AlertController {
  private class ContentView: UIView {
    let buttons: [UIButton]

    init(image: UIImage, title: String, message: String, actions: [Action]) {
      self.buttons = actions.map {
        let configurations: (title: ButtonTitleConfiguration, appearance: ButtonAppearanceConfiguration) = switch $0.style {
        case .default:
          (.defaultTitle, .buttonNormalAppearance)
        case .destructive:
            (.redTitle, .buttonDeleteAppearance)
        case .cancel:
            (.cancelTitle, .buttonCancelAppearance)
        }
        return StyledButton(
          title: $0.title,
          titleConfiguration: configurations.title,
          appearanceConfiguration: configurations.appearance
        )
      }
      super.init(frame: .zero)
      backgroundColor = .white
      layer.cornerRadius = 8

      let contentLayoutGuide = UILayoutGuide()
      addLayoutGuide(contentLayoutGuide)
      contentLayoutGuide.snp.makeConstraints {
        $0.directionalEdges.equalToSuperview().inset(20)
      }

      let imageView = UIImageView(image: image).then {
        $0.contentMode = .scaleAspectFit
      }
      addSubview(imageView)
      imageView.snp.makeConstraints {
        $0.top.centerX.equalTo(contentLayoutGuide).inset(5)
        $0.size.equalTo(40)
      }

      let titleLabel = StyledLabel(config: .titleSemi16).then {
        $0.text = title
        $0.textAlignment = .center
      }
      addSubview(titleLabel)
      titleLabel.snp.makeConstraints {
        $0.top.equalTo(imageView.snp.bottom).offset(8)
        $0.centerX.equalTo(contentLayoutGuide)
        $0.leading.greaterThanOrEqualTo(contentLayoutGuide)
        $0.trailing.lessThanOrEqualTo(contentLayoutGuide)
      }

      let messageLabel = StyledLabel(config: .body12).then {
        $0.text = message
        $0.textColor = .gray500
        $0.numberOfLines = 0
        $0.textAlignment = .center
      }
      addSubview(messageLabel)
      messageLabel.snp.makeConstraints {
        $0.top.equalTo(titleLabel.snp.bottom).offset(8)
        $0.centerX.equalTo(contentLayoutGuide)
        $0.leading.greaterThanOrEqualTo(contentLayoutGuide)
        $0.trailing.lessThanOrEqualTo(contentLayoutGuide)
      }

      let buttonStackView = UIStackView(arrangedSubviews: buttons).then {
        $0.axis = .horizontal
        $0.spacing = 12
      }
      addSubview(buttonStackView)
        
    buttons.forEach {
      $0.snp.makeConstraints {
        $0.width.equalTo(70)
        $0.height.equalTo(30)
      }
    }
      buttonStackView.snp.makeConstraints {
        $0.top.equalTo(messageLabel.snp.bottom).offset(16)
        $0.bottom.equalTo(contentLayoutGuide)
        $0.centerX.equalTo(contentLayoutGuide)
        $0.leading.greaterThanOrEqualTo(contentLayoutGuide)
        $0.trailing.lessThanOrEqualTo(contentLayoutGuide)
      }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
  }
}

// MARK: - AlertTransitioningDelegate

private class AlertTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
  func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    return PresentationAnimator()
  }

  func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    return DismissalAnimator()
  }

  func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
    return PresentationController(
      presentedViewController: presented,
      presenting: presenting
    )
  }

  private class AlertTransitioningAnimator: UIViewPropertyAnimator {
    init() {
      let timingParameters = UISpringTimingParameters(duration: 0.3, bounce: 0.35)
      super.init(duration: 0.3, timingParameters: timingParameters)
    }
  }

  private class PresentationAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
      return 0.3
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
      guard let toViewController = transitionContext.viewController(forKey: .to) else {
        transitionContext.completeTransition(true)
        return
      }
      transitionContext.containerView.addSubview(toViewController.view)
      toViewController.view.frame = transitionContext.finalFrame(for: toViewController)

      toViewController.view.alpha = 0
      toViewController.view.transform = CGAffineTransform(scaleX: 0.87, y: 0.87).translatedBy(x: 0, y: 40)

      let animator = AlertTransitioningAnimator()
      animator.addAnimations {
        toViewController.view.alpha = 1
        toViewController.view.transform = .identity
      }
      animator.addCompletion {
        transitionContext.completeTransition($0 == .end)
      }
      animator.startAnimation()
    }
  }

  private class DismissalAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
      return 0.3
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
      guard let fromViewController = transitionContext.viewController(forKey: .from) else {
        transitionContext.completeTransition(true)
        return
      }

      let animator = AlertTransitioningAnimator()
      animator.addAnimations {
        fromViewController.view.alpha = 0
        fromViewController.view.transform = CGAffineTransform(scaleX: 0.87, y: 0.87).translatedBy(x: 0, y: 40)
      }
      animator.addCompletion {
        transitionContext.completeTransition($0 == .end)
      }
      animator.startAnimation()
    }
  }

  private class PresentationController: UIPresentationController {
    let backgroundView = UIView().then {
      $0.backgroundColor = .black.withAlphaComponent(0.35)
      $0.alpha = 0
    }

    override func presentationTransitionWillBegin() {
      super.presentationTransitionWillBegin()
      containerView?.addSubview(backgroundView)

      let animator = AlertTransitioningAnimator()
      animator.addAnimations {
        self.backgroundView.alpha = 1
      }
      animator.startAnimation()
    }

    override func dismissalTransitionWillBegin() {
      super.dismissalTransitionWillBegin()

      let animator = AlertTransitioningAnimator()
      animator.addAnimations {
        self.backgroundView.alpha = 0
      }
      animator.startAnimation()
    }

    override func containerViewDidLayoutSubviews() {
      super.containerViewDidLayoutSubviews()
      backgroundView.frame = containerView?.bounds ?? .zero
    }
  }
}

// MARK: - AlertController (Rx)

#if canImport(RxSwift) && canImport(RxCocoa)

import RxSwift
import RxCocoa

extension Reactive where Base: AlertController {
  static func alert(
    on viewController: UIViewController?,
    image: UIImage,
    title: String,
    message: String,
    actions: [AlertController.Action]
  ) -> ControlEvent<AlertController.Action> {
    let source = Observable<AlertController.Action>.create { [weak viewController] observer in
      guard let viewController else {
        observer.on(.completed)
        return Disposables.create()
      }
      let alertController = AlertController(
        image: image,
        title: title,
        message: message,
        actions: actions.map {
          AlertController.Action(title: $0.title, style: $0.style) { action in
            observer.on(.next(action))
            observer.on(.completed)
          }
        }
      )
      viewController.present(alertController, animated: true)
      return Disposables.create {
        if alertController.presentingViewController != nil {
          alertController.dismiss(animated: true)
        }
      }
    }
    return ControlEvent(events: source)
  }
}

#endif

// MARK: - AlertController Preview

#Preview {
  final class AlertPreviewController: UIViewController {
    override func viewDidLoad() {
      super.viewDidLoad()
      let action = UIAction(title: "Present Alert") { [weak self] _ in
        let alertController = AlertController(
          image: UIImage(systemName: "exclamationmark.circle.fill")!,
          title: "‘토마토’를 삭제하시겠습니까?",
          message: "삭제하시면 다시 복구시킬 수 없습니다.",
          actions: [
            .cancel("취소") { _ in
            },
            .destructive("삭제") { _ in
            }
          ]
        )
        self?.present(alertController, animated: true)
      }
      let button = UIButton(configuration: .filled(), primaryAction: action)
      view.addSubview(button)
      button.snp.makeConstraints {
        $0.center.equalToSuperview()
      }
    }
  }
  return AlertPreviewController()
}
