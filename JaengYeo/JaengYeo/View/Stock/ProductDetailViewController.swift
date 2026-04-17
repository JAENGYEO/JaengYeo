//
//  ProductDetailViewController.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/16/26.
//

import UIKit
import Then
import SnapKit
import RxSwift
import RxCocoa


final class ProductDetailViewController: BaseViewController {
    

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
            viewDidLoad: Observable.just(())
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
