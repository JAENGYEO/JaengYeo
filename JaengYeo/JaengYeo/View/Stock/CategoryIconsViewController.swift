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
    private let iconsViewHeight = 356
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
        configurePresentation()
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
                self?.selectIcon(named: iconName)
            })
            .disposed(by: disposeBag)

        /// 완료 버튼 선택
        categoryIconsView.applyButton.rx.tap
            .bind(onNext: { [weak self] in
                self?.applySelectedIcon()
            })
            .disposed(by: disposeBag)
    }
}

//MARK: - Action
private extension CategoryIconsViewController {
    /// 배경 선택 이벤트
    @objc
    func didTapBackground(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        
        if !categoryIconsView.frame.contains(location) {
            close()
        }
    }
    
    /// 아이콘 선택
    func selectIcon(named iconName: String) {
        selectedIconName = iconName
    }
    
    /// 선택 아이콘 적용
    func applySelectedIcon() {
        guard let selectedIconName else { return }
        onApply?(selectedIconName)
        close()
    }
    
    /// 화면 닫기
    func close() {
        dismiss(animated: true)
    }
}

//MARK: - Configure
private extension CategoryIconsViewController {
    /// 모달 설정
    func configurePresentation() {
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .coverVertical
        overrideUserInterfaceStyle = .light
    }
    
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
        view.backgroundColor = .clear
        view.overrideUserInterfaceStyle = .light
        
        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(didTapBackground)
        )
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)

        view.addSubview(categoryIconsView)

        categoryIconsView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
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
