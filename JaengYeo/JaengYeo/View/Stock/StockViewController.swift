//
//  StockViewController.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/7/26.
//

import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

final class StockViewController: UIViewController {

    //MARK: - ViewModel
    private let viewModel: StockViewModel

    //MARK: - Properties
    private let disposeBag = DisposeBag()
    

    //MARK: - Components
    private let mainCategorySegment = UISegmentedControl().then {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: LabelConfiguration.bodyMedium14.font,
            .foregroundColor: UIColor.black
        ]
        let selectAttributes:
        [NSAttributedString.Key: Any] = [
            .font: LabelConfiguration.bodyMedium14.font,
            .foregroundColor: UIColor.white
        ]
        $0.setTitleTextAttributes(attributes, for: .normal)
        $0.setTitleTextAttributes(selectAttributes, for: .selected)

        $0.selectedSegmentTintColor = .accent
    }

    private let categoryFilterView = CategoryFilterView()
    
    private let productCollectionView = ProductCollectionView()

    //MARK: - Init
    init(viewModel: StockViewModel) {
        self.viewModel = viewModel
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
}

//MARK: - Binding
private extension StockViewController {
    func bind() {
        let input = StockViewModel.Input(
            viewDidLoad: Observable.just(()),
            mainCategorySelected: mainCategorySegment.rx.selectedSegmentIndex
                .asObservable()
                .filter { $0 >= 0 }
        )
        
        let output = viewModel.transform(input)
        
        output.mainCategories
            .bind(onNext: { [weak self] categories in
                guard let self else { return }
                
                self.mainCategorySegment.removeAllSegments()
                categories.enumerated().forEach { index, title in
                    self.mainCategorySegment.insertSegment(
                        withTitle: title,
                        at: index,
                        animated: false
                    )
                }
                mainCategorySegment.selectedSegmentIndex = 0
            })
            .disposed(by: disposeBag)
        
        output.products
            .bind(onNext: { [weak self] products in
                guard let self else { return }
                self.productCollectionView.applySnapshot(with: products)
            })
            .disposed(by: disposeBag)
    }
}

//MARK: - Action
private extension StockViewController {
    @objc
    private func didTapSearchButton() {
    }
}

//MARK: - Configure UI
private extension StockViewController {
    func configureNavigationBar() {
        title = "재고현황"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "magnifyingglass"),
            style: .plain,
            target: self,
            action: #selector(didTapSearchButton)
        )
    }
    
    private func configureUI() {
        view.addSubview(mainCategorySegment)
        view.addSubview(categoryFilterView)
        view.addSubview(productCollectionView)

        mainCategorySegment.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(40)
        }
        categoryFilterView.snp.makeConstraints {
            $0.top.equalTo(mainCategorySegment.snp.bottom)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(46)
        }
        productCollectionView.snp.makeConstraints {
            $0.top.equalTo(categoryFilterView.snp.bottom)
            $0.leading.equalToSuperview()
            $0.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
        
    }
}

