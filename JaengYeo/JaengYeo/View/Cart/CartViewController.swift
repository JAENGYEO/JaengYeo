//
//  CartViewController.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/28/26.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

final class CartViewController: BaseViewController {

    //MARK: - ViewModel
    private let viewModel: CartViewModel?
    
    //MARK: - Properties
    private let disposeBag = DisposeBag()
    
    
    //MARK: - Init
    init(viewModel: CartViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        overrideUserInterfaceStyle = .light
    }

    init() {
        self.viewModel = nil
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

//MARK: - Binding
private extension CartViewController {
    func bind() {
        guard let viewModel else { return }

        let input = CartViewModel.Input(
            viewDidLoad: Observable.just(())
        )
        
        _ = viewModel.transform(input)
    }
}

//MARK: - Configure UI
private extension CartViewController {
    func configureUI() {
        view.backgroundColor = .white
        navigationItem.title = "장바구니"
    }
}

#Preview {
    BaseNavigationController(
        rootViewController: CartViewController()
    )
}
