//
//  CategoryIconsViewController.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/15/26.
//

import RxCocoa
import RxSwift
import SnapKit
import UIKit

final class CategoryIconsViewController: UIViewController {

    //MARK: - Properties
    private let iconsViewHeight = 325
    private let iconNames: [String]
    private let disposeBag = DisposeBag()
    private var selectedIconName: String?
    var onApply: ((String) -> Void)?

    //MARK: - Components
    private let categoryIconsView = CategoryIconsView()

    //MARK: - Init
    init(
        iconNames: [String],
        selectedIconName: String? = nil
    ) {
        self.iconNames = iconNames
        self.selectedIconName = selectedIconName
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureUI()
        configureData()
        bind()
    }
}

//MARK: - Bind
private extension CategoryIconsViewController {
    func bind() {
        /// 아이콘 선택
        categoryIconsView.collectionView.rx.itemSelected
            .compactMap { [weak self] indexPath in
                self?.categoryIconsView.iconName(at: indexPath)
            }
            .bind(onNext: { [weak self] iconName in
                self?.selectedIconName = iconName
            })
            .disposed(by: disposeBag)

        /// 완료 버튼 선택
        categoryIconsView.applyButton.rx.tap
            .compactMap { [weak self] in
                self?.selectedIconName
            }
            .bind(onNext: { [weak self] iconName in
                guard let self else { return }
                self.onApply?(iconName)
                self.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
    }
}

//MARK: - Configure
private extension CategoryIconsViewController {
    /// 네비게이션 바 설정
    func configureNavigationBar() {
        title = "아이콘 선택"
        navigationController?.navigationBar.tintColor = .gray800
    }

    /// 데이터 설정
    func configureData() {
        categoryIconsView.updateIcons(
            iconNames: iconNames,
            selectedIconName: selectedIconName
        )
    }

    /// UI 설정
    func configureUI() {
        view.backgroundColor = .white
        view.addSubview(categoryIconsView)

        categoryIconsView.snp.makeConstraints {
            $0.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(iconsViewHeight)
        }
    }
}

#Preview {
    UINavigationController(
        rootViewController: CategoryIconsViewController(
            iconNames: FoodSubCategoryIcon.iconNames
        )
    )
}
