//
//  RegisterCompleteViewController.swift
//  JaengYeo
//
//  Created by 손영빈 on 5/4/26.
//

import UIKit
import RxSwift
import RxCocoa

protocol RegisterCompleteViewControllerDelegate: AnyObject {
    func didTapStockButton()
    func didTapHomeButton()
}

final class RegisterCompleteViewController: BaseViewController {
    private let mainView = RegisterCompleteView()
    private let disposeBag = DisposeBag()
    weak var delegate: RegisterCompleteViewControllerDelegate?
    
    override func loadView() {
        self.view = mainView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        bind()
    }
}

extension RegisterCompleteViewController {
    private func bind() {
        mainView.stockButton.rx.tap
            .bind(onNext: { [weak self] in
                self?.delegate?.didTapStockButton()
            })
            .disposed(by: disposeBag)
        mainView.homeButton.rx.tap
            .bind(onNext: { [weak self] in
                self?.delegate?.didTapHomeButton()
            })
            .disposed(by: disposeBag)
    }
}
