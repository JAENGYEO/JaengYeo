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

enum CategoryEditMode {
    case add(CategoryEditTarget, String)
    case edit(CategoryEditTarget, CategoryEditItem, String)

    var navigationTitle: String {
        switch self {
        case .add(let target, _):
            return "\(target.title) 카테고리 추가"
        case .edit(let target, _, _):
            return "\(target.title) 카테고리 편집"
        }
    }

    var buttonTitle: String {
        switch self {
        case .add:
            return "카테고리 생성"
        case .edit:
            return "카테고리 수정"
        }
    }

    var item: CategoryEditItem? {
        switch self {
        case .add:
            return nil
        case .edit(_, let item, _):
            return item
        }
    }
}

final class CategoryEditDetailViewController: UIViewController {

    //MARK: - Properties
    private let mode: CategoryEditMode
    private let viewModel: CategoryEditDetailViewModel
    private let disposeBag = DisposeBag()

    //MARK: - Components
    private let inputContainerView = UIView().then {
        $0.backgroundColor = .white
    }

    private let categoryImageView = UIImageView().then {
        $0.image = UIImage(named: "iconSelectIcon")
        $0.contentMode = .scaleAspectFit
    }

    private let nameTextField = UITextField().then {
        $0.font = LabelConfiguration.bodyMedium14.font
        $0.textColor = .gray800
        $0.placeholder = "분류 이름을 입력해주세요"
    }

    private let textFieldLineView = UIView().then {
        $0.backgroundColor = .gray200
    }

    private let deleteButton = StyledButton(
        title: "삭제",
        titleConfiguration: .redTitle,
        appearanceConfiguration: .redAppearance
    )

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
        let input = CategoryEditDetailViewModel.Input(
            nameText: nameTextField.rx.text.asObservable(),
            confirmTapped: confirmButton.rx.tap.asObservable(),
            deleteTapped: deleteButton.rx.tap.asObservable()
        )

        let output = viewModel.transform(input)

        output.completed
            .bind(onNext: { [weak self] in
                guard let self else { return }
                self.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
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
            deleteButton.isEnabled = false
            return
        }

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

