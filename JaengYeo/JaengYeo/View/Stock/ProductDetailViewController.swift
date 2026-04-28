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
        didTapModify formData: RegisterFormData,
        originalPayload: ProductPayload
    )
}

final class ProductDetailViewController: BaseViewController {

    weak var delegate: ProductDetailViewControllerDelegate?

    let viewModel: ProductDetailViewModel

    let disposeBag = DisposeBag()
    private let viewWillAppearRelay = PublishRelay<Void>()

    let productDetailView = ProductDetailView()

    //MARK: - Init
    init(viewModel: ProductDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        overrideUserInterfaceStyle = .light         
        title = "상세 정보"
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureUI()
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearRelay.accept(())
    }
}

extension ProductDetailViewController {
    private func bind() {

        let deleteTap = productDetailView.deleteButton.rx.tap
            .flatMapLatest { [weak self] _ in
                AlertController.rx.alert(
                    on: self,
                    image: UIImage(named: "alertRed") ?? UIImage(),
                    title: "상품 삭제",
                    message: "해당 상품을 삭제하시겠습니까?",
                    actions: [
                        .cancel("취소"),
                        .destructive("삭제")
                    ]
                )
            }
            .filter { $0.title == "삭제"}
            .map { _ in }
            .asObservable()
        
        let input = ProductDetailViewModel.Input(
            viewDidLoad: Observable.just(()),
            viewWillAppear: viewWillAppearRelay.asObservable(),
            modifyTapped: productDetailView.modifyButton.rx.tap.asObservable(),
            deleteTapped: deleteTap
        )

        let output = viewModel.transform(input)

        output.viewUpdate
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] displayModel in
                guard let self else { return }
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
                    if isdeleted {
                        if let nav = navigationController,
                            nav.viewControllers.first != self
                        {
                            nav.popViewController(animated: true)
                        }
                    } else {
                        AlertController.rx.alert(
                            on: self,
                            image: UIImage(named: "alertRed") ?? UIImage(),
                            title: "삭제 실패",
                            message: "상품을 삭제하는 중 오류가 발생했습니다.",
                            actions: [.default("확인")]
                        ).subscribe().disposed(by: disposeBag)
                    }
                }
            })
            .disposed(by: disposeBag)

        output.modify
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] formData, originalPayload in
                guard let self else { return }
                delegate?.productDetailViewController(
                    self,
                    didTapModify: formData,
                    originalPayload: originalPayload
                )
            })
            .disposed(by: disposeBag)

    }
}

extension ProductDetailViewController {

    func configureNavigationBar() {
        title = "상세 정보"

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .font: LabelConfiguration.titleSemi18.font,
            .foregroundColor: UIColor.gray800
        ]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .gray800
    }
    
    private func configureUI() {
        view.backgroundColor = .white
        view.addSubview(productDetailView)

        productDetailView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}
