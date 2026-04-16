//
//  CategoryEditDetailViewController.swift
//  JaengYeo
//
//  Created by Codex on 4/14/26.
//

import SnapKit
import Then
import UIKit
import RxCocoa
import RxSwift

/// 편집 대상 분류
enum CategoryEditTarget {
    case midCategory
    case subCategory

    var title: String {
        switch self {
        case .midCategory:
            return "중분류"
        case .subCategory:
            return "소분류"
        }
    }
}

/// 분류 편집 화면 모드
enum CategoryEditMode {
    case add(CategoryEditTarget, String)
    case edit(CategoryEditTarget, CategoryEditItem, String)

    /// 네비게이션 타이틀
    var navigationTitle: String {
        switch self {
        case .add(let target, _):
            return "\(target.title) 카테고리 추가"
        case .edit(let target, _, _):
            return "\(target.title) 카테고리 편집"
        }
    }

    /// 완료 버튼 타이틀
    var buttonTitle: String {
        switch self {
        case .add:
            return "카테고리 생성"
        case .edit:
            return "카테고리 수정"
        }
    }

    /// 편집 아이템
    var item: CategoryEditItem? {
        switch self {
        case .add:
            return nil
        case .edit(_, let item, _):
            return item
        }
    }

    /// 선택 가능 아이콘 목록
    var iconNames: [String] {
        switch (target, mainCategory) {
        case (.midCategory, MainCategory.foodstuff.rawValue):
            return FoodMidCategoryIcon.iconNames
        case (.subCategory, MainCategory.foodstuff.rawValue):
            return FoodSubCategoryIcon.iconNames
        case (.midCategory, MainCategory.household.rawValue):
            return HouseholdMidCategoryIcon.iconNames
        case (.subCategory, MainCategory.household.rawValue):
            return HouseholdSubCategoryIcon.iconNames
        default:
            return ["categoryIcon"]
        }
    }

    /// 현재 선택된 아이콘 이름
    var selectedIconName: String? {
        item?.iconName
    }

    private var target: CategoryEditTarget {
        switch self {
        case .add(let target, _):
            return target
        case .edit(let target, _, _):
            return target
        }
    }
    
    private var mainCategory: String {
        switch self {
        case .add(_, let mainCategory):
            return mainCategory
        case .edit(_, _, let mainCategory):
            return mainCategory
        }
    }
}

final class CategoryEditDetailViewController: UIViewController {

    //MARK: - Properties
    /// 편집 모드
    private let mode: CategoryEditMode
    /// 뷰모델
    private let viewModel: CategoryEditDetailViewModel
    /// 메모리 해제 가방
    private let disposeBag = DisposeBag()
    /// 아이콘 선택값 전달
    private let iconNameSelectedRelay = PublishRelay<String>()
    /// 현재 선택된 아이콘 이름
    private var selectedIconName: String?

    //MARK: - Components
    /// 입력 영역 뷰
    private let inputContainerView = UIView().then {
        $0.backgroundColor = .white
    }

    /// 카테고리 이미지 뷰
    private let categoryImageView = UIImageView().then {
        $0.image = UIImage(named: "iconSelectIcon")
        $0.contentMode = .scaleAspectFit
        $0.isUserInteractionEnabled = true
    }

    /// 분류 이름 입력 필드
    private let nameTextField = UITextField().then {
        $0.font = LabelConfiguration.bodyMedium14.font
        $0.textColor = .gray800
        $0.placeholder = "분류 이름을 입력해주세요"
    }

    /// 입력 필드 하단 라인
    private let textFieldLineView = UIView().then {
        $0.backgroundColor = .gray200
    }

    /// 삭제 버튼
    private let deleteButton = StyledButton(
        title: "삭제",
        titleConfiguration: .redTitle,
        appearanceConfiguration: .redAppearance
    )

    /// 생성/수정 버튼
    private lazy var confirmButton = StyledButton(
        title: mode.buttonTitle,
        titleConfiguration: .defaultTitle,
        appearanceConfiguration: .defaultAppearance
    )

    //MARK: - Init
    init(
        mode: CategoryEditMode,
        viewModel: CategoryEditDetailViewModel
    ) {
        self.mode = mode
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
        configureData()
        bind()
    }
}

//MARK: - Bind
private extension CategoryEditDetailViewController {
    func bind() {
        let deleteConfirmedRelay = PublishRelay<Void>()

        let input = CategoryEditDetailViewModel.Input(
            nameText: nameTextField.rx.text.asObservable(),
            iconNameSelected: iconNameSelectedRelay.asObservable(),
            confirmTapped: confirmButton.rx.tap.asObservable(),
            deleteTapped: deleteConfirmedRelay.asObservable()
        )

        let output = viewModel.transform(input)

        output.completed
            .bind(onNext: { [weak self] in
                guard let self else { return }
                self.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)

        /// 삭제 버튼 선택
        deleteButton.rx.tap
            .bind(onNext: {
                //TODO: 삭제 알림 화면 추가 필요
                deleteConfirmedRelay.accept(())
            })
            .disposed(by: disposeBag)

        /// 아이콘 선택 화면 표시
        let tapGesture = UITapGestureRecognizer()
        categoryImageView.addGestureRecognizer(tapGesture)
        
        tapGesture.rx.event
            .bind(onNext: { [weak self] _ in
                self?.presentCategoryIcons()
            })
            .disposed(by: disposeBag)
    }
}

//MARK: - Present
private extension CategoryEditDetailViewController {
    /// 아이콘 선택 화면 표시
    func presentCategoryIcons() {
        let viewController = CategoryIconsViewController(
            iconNames: mode.iconNames,
            selectedIconName: selectedIconName
        )
        
        viewController.onApply = { [weak self] iconName in
            guard let self else { return }
            self.selectedIconName = iconName 
            self.categoryImageView.image = UIImage(named: iconName)
            self.iconNameSelectedRelay.accept(iconName)
        }
        
        present(viewController, animated: false)
    }
}

//MARK: - Configure
private extension CategoryEditDetailViewController {
    /// 네비게이션 바 설정
    func configureNavigationBar() {
        title = mode.navigationTitle
        navigationController?.navigationBar.tintColor = .gray800
    }

    /// 데이터 설정
    func configureData() {
        guard let item = mode.item else {
            selectedIconName = nil
            deleteButton.isEnabled = false
            return
        }

        selectedIconName = item.iconName
        categoryImageView.image = item.image
        nameTextField.text = item.title
        deleteButton.isEnabled = item.userId != nil
    }

    /// UI 설정
    func configureUI() {
        view.backgroundColor = .white

        view.addSubview(inputContainerView)
        view.addSubview(deleteButton)
        view.addSubview(confirmButton)

        inputContainerView.addSubview(categoryImageView)
        inputContainerView.addSubview(nameTextField)
        inputContainerView.addSubview(textFieldLineView)

        inputContainerView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(112)
        }

        categoryImageView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.equalToSuperview().offset(24)
            $0.size.equalTo(40)
        }

        nameTextField.snp.makeConstraints {
            $0.top.equalTo(categoryImageView.snp.bottom).offset(24)
            $0.leading.equalToSuperview().offset(24)
            $0.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(24)
        }

        textFieldLineView.snp.makeConstraints {
            $0.top.equalTo(nameTextField.snp.bottom).offset(9.5)
            $0.leading.trailing.equalTo(nameTextField)
            $0.height.equalTo(1)
        }

        deleteButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(24)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.width.equalTo(82)
            $0.height.equalTo(44)
        }

        confirmButton.snp.makeConstraints {
            $0.leading.equalTo(deleteButton.snp.trailing).offset(16)
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalTo(deleteButton)
            $0.height.equalTo(44)
        }
    }
}
