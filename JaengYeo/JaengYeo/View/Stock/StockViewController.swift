//
//  StockViewController.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/7/26.
//

import RxCocoa
import RxRelay
import RxSwift
import SnapKit
import Then
import UIKit

protocol StockViewControllerDelegate: AnyObject {
    func didTapCategoryEditButton()
    func didTapSearchButton()
    func didSelectProduct(productID: UUID)
}

final class StockViewController: BaseViewController {

    //MARK: - ViewModel
    private let viewModel: StockViewModel

    //MARK: - Properties
    private let disposeBag = DisposeBag()
    weak var delegate: StockViewControllerDelegate?

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
        $0.backgroundColor = .gray50
    }

    private let categoryFilterView = CategoryFilterView()
    
    private let productCollectionView = ProductCollectionView()

    //MARK: - Init
    init(viewModel: StockViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        overrideUserInterfaceStyle = .light
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
        /// 상품 재고 차감 선택
        let productQuantityDecreasedRelay = PublishRelay<ProductCellItem>()
        /// 상품 삭제 선택
        let productDeletedRelay = PublishRelay<[UUID]>()
        
        productCollectionView.configureSortMenu { sortOption in
            sortOptionSelectedRelay.accept(sortOption)
        }
        
        productCollectionView.itemSelected
            .bind(onNext: { [weak self] item in
                self?.selectProduct(item)
            })
            .disposed(by: disposeBag)
        
        productCollectionView.itemQuantityDecreased
            .bind(to: productQuantityDecreasedRelay)
            .disposed(by: disposeBag)
        
        productCollectionView.itemDeleted
            .flatMapLatest { [weak self] item -> Observable<[UUID]> in
                guard let self else { return .empty() }
                return self.showDeleteAlert(item: item)
            }
            .bind(to: productDeletedRelay)
            .disposed(by: disposeBag)
        
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
            sortOptionSelected: sortOptionSelectedRelay.asObservable(),
            productQuantityDecreased: productQuantityDecreasedRelay.asObservable(),
            productDeleted: productDeletedRelay.asObservable()
        )
        
        /// 카테고리 편집 버튼 바인딩
        categoryFilterView.categoryEditButton.rx.tap
            .bind(onNext: { [weak self] in
                guard let self else { return }
                self.delegate?.didTapCategoryEditButton()
            })
            .disposed(by: disposeBag)
        
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
        delegate?.didTapSearchButton()
    }
    
    /// 카테고리 선택 모달 표시
    func presentCategorySelection(
        items: [CategorySelectionItem],
        onApply: @escaping ([String]) -> Void
    ) {
        let viewController = CategorySelectionViewController(items: items)
        viewController.onApply = onApply
        present(viewController, animated: false)
    }
    
    /// 상품 선택
    func selectProduct(_ item: ProductCellItem) {
        guard item.isGrouped else {
            delegate?.didSelectProduct(productID: item.product.id)
            return
        }
        
        presentProductGroupList(item)
    }
    
    /// 그룹 상품 목록 모달 표시
    func presentProductGroupList(_ item: ProductCellItem) {
        let viewController = ProductGroupListViewController(
            viewModel: ProductGroupListViewModel(items: item.groupedItems)
        )
        
        viewController.onSelect = { [weak self] productID in
            self?.delegate?.didSelectProduct(productID: productID)
        }
        
        present(viewController, animated: false)
    }
    
    /// 상품 삭제 알럿 표시
    func showDeleteAlert(item: ProductCellItem) -> Observable<[UUID]> {
        let productIDs = item.deleteTargetProductIDs
        
        return AlertController.rx.alert(
            on: self,
            image: UIImage(named: "alertRed") ?? UIImage(),
            title: "상품 삭제",
            message:  item.isGrouped
            ? "같은 이름의 상품 \(item.groupedCount)건을 삭제하시겠습니까?"
            : "해당 상품을 삭제하시겠습니까?",
            actions: [
                .cancel("취소"),
                .destructive("삭제")
            ]
        )
        .filter { $0.title == "삭제" }
        .map { _ in productIDs }
        .asObservable()
    }
}

//MARK: - ProductCellItem
private extension ProductCellItem {
    /// 삭제 대상 상품 ID 목록
    var deleteTargetProductIDs: [UUID] {
        if isGrouped {
            return groupedItems.map { $0.product.id }
        }
        
        return [product.id]
    }
}

//MARK: - Configure UI
private extension StockViewController {
    func configureNavigationBar() {
        title = "재고현황"
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.titleTextAttributes = [
            .font: LabelConfiguration.titleSemi18.font,
            .foregroundColor: UIColor.gray800
        ]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .gray800
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "magnifyingglass"),
            style: .plain,
            target: self,
            action: #selector(didTapSearchButton)
        )
    }
    
    private func configureUI() {
        view.backgroundColor = .white
        
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
            $0.height.equalTo(40)
        }
        productCollectionView.snp.makeConstraints {
            $0.top.equalTo(categoryFilterView.snp.bottom).offset(8)
            $0.leading.equalToSuperview()
            $0.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
    }
}

// Home에서 세그먼트 변경 후 접근할 메서드
extension StockViewController {
    func selectMainCategory(name: String) {
        guard let index = (0..<mainCategorySegment.numberOfSegments)
            .first(where: { mainCategorySegment.titleForSegment(at: $0) == name }) else { return }
        mainCategorySegment.selectedSegmentIndex = index
        mainCategorySegment.sendActions(for: .valueChanged)
    }
}
