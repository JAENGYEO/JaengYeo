//
//  StockViewController.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/7/26.
//

import RxCocoa
import RxRelay
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
            .foregroundColor: UIColor.gray800
        ]
        let selectAttributes:
        [NSAttributedString.Key: Any] = [
            .font: LabelConfiguration.bodyMedium14.font,
            .foregroundColor: UIColor.accent
        ]
        $0.setTitleTextAttributes(attributes, for: .normal)
        $0.setTitleTextAttributes(selectAttributes, for: .selected)

        $0.selectedSegmentTintColor = .white
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
        /// 중분류 적용 결과
        let midCategoryAppliedRelay = PublishRelay<[String]>()
        /// 소분류 적용 결과
        let subCategoryAppliedRelay = PublishRelay<[String]>()
        /// 상품 정렬 선택
        let sortOptionSelectedRelay = PublishRelay<ProductSortOption>()
        
        productCollectionView.configureSortMenu { sortOption in
            sortOptionSelectedRelay.accept(sortOption)
        }
        
        /// ViewModel 입력값
        let input = StockViewModel.Input(
            viewDidLoad: Observable.just(()),
            mainCategorySelected: mainCategorySegment.rx.selectedSegmentIndex
                .asObservable()
                .filter { $0 >= 0 },
            midCategoryTapped: categoryFilterView.midCategoryButton.rx.tap.asObservable(),
            subCategoryTapped: categoryFilterView.subCategoryButton.rx.tap.asObservable(),
            midCategoryApplied: midCategoryAppliedRelay.asObservable(),
            subCategoryApplied: subCategoryAppliedRelay.asObservable(),
            sortOptionSelected: sortOptionSelectedRelay.asObservable()
        )
        
        let output = viewModel.transform(input)
        
        /// 메인 카테고리 바인딩
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
        
        /// 상품 목록 바인딩
        output.products
            .bind(onNext: { [weak self] products in
                guard let self else { return }
                self.productCollectionView.applySnapshot(with: products)
            })
            .disposed(by: disposeBag)
        
        /// 정렬 타이틀 바인딩
        output.selectedSortTitle
            .bind(onNext: { [weak self] title in
                guard let self else { return }
                self.productCollectionView.updateSortTitle(title)
            })
            .disposed(by: disposeBag)
        
        /// 중분류 버튼 선택 상태 바인딩
        output.isMidCategorySelected
            .bind(onNext: { [weak self] isSelected in
                guard let self else { return }
                self.categoryFilterView.midCategoryButton.isSelected = isSelected
            })
            .disposed(by: disposeBag)
        
        /// 소분류 버튼 선택 상태 바인딩
        output.isSubCategorySelected
            .bind(onNext: { [weak self] isSelected in
                guard let self else { return }
                self.categoryFilterView.subCategoryButton.isSelected = isSelected
            })
            .disposed(by: disposeBag)
        
        /// 중분류 선택 모달 표시
        output.presentMidCategoryItems
            .bind(onNext: { [weak self] items in
                guard let self else { return }
                self.presentCategorySelection(items: items) { selectedIDs in
                    midCategoryAppliedRelay.accept(selectedIDs)
                }
            })
            .disposed(by: disposeBag)
        
        /// 소분류 선택 모달 표시
        output.presentSubCategoryItems
            .bind(onNext: { [weak self] items in
                guard let self else { return }
                self.presentCategorySelection(items: items) { selectedIDs in
                    subCategoryAppliedRelay.accept(selectedIDs)
                }
            })
            .disposed(by: disposeBag)
    }
}

//MARK: - Action
private extension StockViewController {
    @objc
    private func didTapSearchButton() {
    }
    
    /// 카테고리 선택 모달 표시
    func presentCategorySelection(
        items: [CategorySelectionItem],
        onApply: @escaping ([String]) -> Void
    ) {
        let viewController = CategorySelectionViewController(items: items)
        viewController.onApply = onApply
        present(viewController, animated: true)
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
            $0.top.equalTo(mainCategorySegment.snp.bottom).offset(8)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(46)
        }
        productCollectionView.snp.makeConstraints {
            $0.top.equalTo(categoryFilterView.snp.bottom).offset(8)
            $0.leading.equalToSuperview()
            $0.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
    }
}
