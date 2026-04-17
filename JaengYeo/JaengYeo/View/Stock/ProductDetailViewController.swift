//
//  ProductDetailViewController.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/16/26.
//

import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

protocol ProductDetailViewControllerDelegate: AnyObject {
    func productDetailViewController(
        _ viewController: ProductDetailViewController,
        didTapModify formData: RegisterFormData
    )
}

final class ProductDetailViewController: UIViewController {

    weak var delegate: ProductDetailViewControllerDelegate?

    let viewModel: ProductDetailViewModel

    let disposeBag = DisposeBag()

    let productDetailView = ProductDetailView()

    //MARK: - Init
    init(viewModel: ProductDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        overrideUserInterfaceStyle = .light
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bind()
    }
}

extension ProductDetailViewController {
    private func bind() {

        let input = ProductDetailViewModel.Input(
            viewDidLoad: Observable.just(()),
            modifyTapped: productDetailView.modifyButton.rx.tap.asObservable(),
            deleteTapped: productDetailView.deleteButton.rx.tap.asObservable()
        )

        let output = viewModel.transform(input)

        output.viewUpdate
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] displayModel in
                guard let self else { return }
                self.title = displayModel.productName
                self.productDetailView.updateUI(displayModel: displayModel)
            })
            .disposed(by: disposeBag)

        output.deleteSuccess
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isdeleted in
                guard let self else { return }
                // TODO: 알럿 추가 에정
                if isdeleted {
                    if let nav = navigationController,
                        nav.viewControllers.first != self
                    {
                        nav.popViewController(animated: true)
                    }
                } else {

                }
            })
            .disposed(by: disposeBag)

        output.modify
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] formData in
                guard let self else { return }
                delegate?.productDetailViewController(
                    self,
                    didTapModify: formData
                )
            })
            .disposed(by: disposeBag)

    }
}

extension ProductDetailViewController {

    private func configureUI() {
        view.backgroundColor = .white
        view.addSubview(productDetailView)

        productDetailView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}
