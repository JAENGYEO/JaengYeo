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

    private let categotyFilterView = CategoryFilterView()
    
    private let productCollectionView = ProductCollectionView()
    

    init(viewModel: StockViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBarConfigure()
        bind()
        configureUI()
    }
}

//MARK: - Binding
extension StockViewController {
    private func bind() {
        viewModel.mainCategory
            .subscribe(onNext: {
                [weak self] items in
                guard let self else { return }
                self.mainCategorySegment.removeAllSegments()
                items.enumerated().forEach { index, title in
                    self.mainCategorySegment.insertSegment(
                        withTitle: title,
                        at: index,
                        animated: false
                    )
                }
            })
            .disposed(by: disposeBag)
    }
}

extension StockViewController {
    @objc
    private func didTapSearchButton() {
    }
}

//MARK: - Configure UI
extension StockViewController {
    private func navigationBarConfigure() {
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
        view.addSubview(categotyFilterView)
        view.addSubview(productCollectionView)
        mainCategorySegment.selectedSegmentIndex = 0

        mainCategorySegment.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(40)
        }
        categotyFilterView.snp.makeConstraints {
            $0.top.equalTo(mainCategorySegment.snp.bottom)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(46)
        }
        productCollectionView.snp.makeConstraints {
            $0.top.equalTo(categotyFilterView.snp.bottom)
            $0.leading.equalToSuperview()
            $0.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
    }
}

