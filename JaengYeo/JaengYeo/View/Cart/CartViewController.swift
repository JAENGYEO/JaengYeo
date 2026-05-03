//
//  CartViewController.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/28/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

protocol CartViewControllerDelegate: AnyObject {
    func didTapExistingProductButton()
    func didTapNewProductButton()
    func didSelectCartItem(_ item: CartItem)
    func didTapConfirmButton(cartItems: [CartItem])
}

final class CartViewController: BaseViewController {

    //MARK: - ViewModel
    private let viewModel: CartViewModel?
    
    //MARK: - Properties
    private let disposeBag = DisposeBag()
    private let viewWillAppearRelay = PublishRelay<Void>()
    private let sortOptionSelectedRelay = PublishRelay<CartSortOption>()
    weak var delegate: CartViewControllerDelegate?

    //MARK: - Components
    private let cartView = CartView()

    private let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)

    
    //MARK: - Init
    init(viewModel: CartViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    init() {
        self.viewModel = nil
        super.init(nibName: nil, bundle: nil)
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

//MARK: - Binding
private extension CartViewController {
    func bind() {
        guard let viewModel else { return }

        let itemDeleted = cartView.itemDeleted
            .flatMapLatest { [weak self] item in
                AlertController.rx.alert(
                    on: self,
                    image: UIImage(named: "alertRed") ?? UIImage(),
                    title: "항목 삭제",
                    message: "구매 예정 항목을 삭제하시겠습니까?",
                    actions: [
                        .cancel("취소"),
                        .destructive("삭제")
                    ]
                )
                .filter { $0.title == "삭제" }
                .map { _ in item }
            }
            .asObservable()

        let input = CartViewModel.Input(
            viewDidLoad: Observable.just(()),
            viewWillAppear: viewWillAppearRelay.asObservable(),
            itemDeleted: itemDeleted,
            itemQuantityIncreased: cartView.itemQuantityIncreased,
            itemQuantityDecreased: cartView.itemQuantityDecreased,
            sortOptionSelected: sortOptionSelectedRelay.asObservable()
        )
        
        let output = viewModel.transform(input)

        output.cartItems
            .bind(onNext: { [weak self] items in
                self?.cartView.applySnapshot(with: items)
            })
            .disposed(by: disposeBag)

        output.selectedSortTitle
            .bind(onNext: { [weak self] title in
                self?.cartView.updateSortTitle(title)
            })
            .disposed(by: disposeBag)

        cartView.itemSelected
            .bind(onNext: { [weak self] item in
                self?.delegate?.didSelectCartItem(item)
            })
            .disposed(by: disposeBag)

        cartView.confirmButtonTap
            .withLatestFrom(output.cartItems)
            .bind(onNext: { [weak self] items in
                self?.delegate?.didTapConfirmButton(cartItems: items)
            })
            .disposed(by: disposeBag)
    }
}

//MARK: - Configure UI
private extension CartViewController {
    func configureNavigationBar() {
        navigationItem.title = "구매 예정 목록"

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

        configureAddMenu()
        navigationItem.rightBarButtonItem = addButton
    }
    
    func configureUI() {
        cartView.configureSortMenu { [weak self] option in
            self?.sortOptionSelectedRelay.accept(option)
        }

        view.addSubview(cartView)

        cartView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }

    func configureAddMenu() {
        let existingProductAction = UIAction(title: "기존제품") { [weak self] _ in
            self?.delegate?.didTapExistingProductButton()
        }

        let newProductAction = UIAction(title: "신규등록") { [weak self] _ in
            self?.delegate?.didTapNewProductButton()
        }

        addButton.menu = UIMenu(
            children: [
                existingProductAction,
                newProductAction
            ]
        )
    }
}

#Preview {
    BaseNavigationController(
        rootViewController: CartViewController()
    )
}
