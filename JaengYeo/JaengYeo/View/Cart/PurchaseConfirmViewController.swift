//
//  PurchaseConfirmViewController.swift
//  JaengYeo
//
//  Created by Hanjuheon on 5/3/26.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

protocol PurchaseConfirmViewControllerDelegate: AnyObject {
    func purchaseConfirmViewControllerDidFinish(
        _ viewController: PurchaseConfirmViewController
    )
    func purchaseConfirmViewControllerDidFinishWithUnclassified(
        _ viewController: PurchaseConfirmViewController
    )
}

final class PurchaseConfirmViewController: BaseViewController {

    //MARK: - ViewModel
    private let viewModel: PurchaseConfirmViewModel

    //MARK: - Properties
    private let disposeBag = DisposeBag()
    private let sortOptionSelectedRelay = PublishRelay<CartSortOption>()
    weak var delegate: PurchaseConfirmViewControllerDelegate?

    //MARK: - Components
    private let confirmView = PurchaseConfirmView()

    //MARK: - Init
    init(viewModel: PurchaseConfirmViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
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
}

//MARK: - Binding
private extension PurchaseConfirmViewController {
    func bind() {
        let confirmTapped = confirmView.confirmButtonTap
            .flatMapLatest { [weak self] _ -> Observable<Void> in
                guard let self else { return .empty() }
                return AlertController.rx.alert(
                    on: self,
                    image: UIImage(named: "alertBlue") ?? UIImage(),
                    title: "오늘 날짜 기준으로 재고가 등록됩니다",
                    message: "확인을 누르시면 선택한 수량만큼 재고에 반영됩니다.\n예정 수량보다 적게 등록한 경우 남은 수량은 구매 예정 목록에 유지됩니다.",
                    actions: [.cancel("취소"), .default("확인")]
                )
                .filter { $0.title == "확인" }
                .map { _ in }
            }

        let input = PurchaseConfirmViewModel.Input(
            viewDidLoad: Observable.just(()),
            selectAllTapped: confirmView.selectAllTap,
            itemCheckTapped: confirmView.itemCheckTap,
            itemQuantityIncreased: confirmView.itemQuantityIncreased,
            itemQuantityDecreased: confirmView.itemQuantityDecreased,
            confirmTapped: confirmTapped,
            sortOptionSelected: sortOptionSelectedRelay.asObservable()
        )

        let output = viewModel.transform(input)

        output.items
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] items in
                self?.confirmView.applySnapshot(items: items)
            })
            .disposed(by: disposeBag)

        output.registerSuccess
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] in
                self?.showSuccessAlert()
            })
            .disposed(by: disposeBag)

        output.registerFailure
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] message in
                self?.showFailureAlert(message: message)
            })
            .disposed(by: disposeBag)

        output.selectedSortTitle
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] title in
                self?.confirmView.updateSortTitle(title)
            })
            .disposed(by: disposeBag)
    }
}

//MARK: - Alert
private extension PurchaseConfirmViewController {
    func showSuccessAlert() {
        AlertController.rx.alert(
            on: self,
            image: UIImage(named: "alertBlue") ?? UIImage(),
            title: "재고 등록 완료",
            message: "선택한 상품이 재고에 등록되었습니다.\n확인 버튼을 누르시면 [미분류 상품] 화면으로 이동합니다.",
            actions: [.default("확인")]
        )
        .bind(onNext: { [weak self] _ in
            guard let self else { return }
            self.delegate?.purchaseConfirmViewControllerDidFinishWithUnclassified(self)
        })
        .disposed(by: disposeBag)
    }

    func showFailureAlert(message: String) {
        AlertController.rx.alert(
            on: self,
            image: UIImage(named: "alertRed") ?? UIImage(),
            title: "등록 실패",
            message: message,
            actions: [.default("확인")]
        )
        .subscribe()
        .disposed(by: disposeBag)
    }
}

//MARK: - Configure UI
private extension PurchaseConfirmViewController {
    func configureNavigationBar() {
        navigationItem.title = "구매 확정"

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

    func configureUI() {
        view.backgroundColor = .white
        confirmView.configureSortMenu { [weak self] option in
            self?.sortOptionSelectedRelay.accept(option)
        }

        view.addSubview(confirmView)

        confirmView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }
}
