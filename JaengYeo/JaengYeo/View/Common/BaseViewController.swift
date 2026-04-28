//
//  BaseViewController.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/17/26.
//

import UIKit

class BaseViewController: UIViewController {
    var handlesKeyboardInset: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboardHandling()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }
}

extension BaseViewController {
    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification, object: nil
        )
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        view.addGestureRecognizer(tap)
    }
    
    @objc
    private func keyboardWillShow(_ notification: Notification) {
        guard handlesKeyboardInset,
              let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let scrollView = findScrollView(in: view),
              let activeField = view.findFirstResponder(),
              activeField.isDescendant(of: scrollView) else { return }
        let inset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardFrame.height
                                 , right: 0)
        scrollView.contentInset = inset
        scrollView.scrollIndicatorInsets = inset
        
        let rect = activeField.convert(activeField.bounds, to: scrollView)
        scrollView.scrollRectToVisible(rect.insetBy(dx: 0, dy: -20), animated: true)
    }
    
    @objc
    private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc
    private func keyboardWillHide(_ notification: Notification) {
        guard handlesKeyboardInset,
              let scrollView = findScrollView(in: view) else { return }
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
    
    private func findScrollView(in view: UIView) -> UIScrollView? {
        if let scrollView = view as? UIScrollView { return scrollView }
        for subview in view.subviews {
            if let found = findScrollView(in: subview) { return found }
        }
        return nil
    }
}

extension UIView {
    func findFirstResponder() -> UIView? {
        if isFirstResponder { return self }
        for subview in subviews {
            if let responder = subview.findFirstResponder() { return responder }
        }
        return nil
    }
}

extension BaseViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var view: UIView? = touch.view
        while let current = view {
            if current is UIControl { return false}
            view = current.superview
        }
        return true
    }
}
