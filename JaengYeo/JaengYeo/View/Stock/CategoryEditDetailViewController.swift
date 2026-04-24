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

final class CategoryEditDetailViewController: BaseViewController {

    //MARK: - Input Limit
    private enum InputLimit {
        static let categoryName = 10
    }

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
        $0.placeholder = "분류 이름을 입력해주세요. (최대 10자)"
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
        configureInputValidation()
        configureKeyboardDismiss()
        bind()
    }
}

//MARK: - Bind
private extension CategoryEditDetailViewController {
    /// 입력 제한 설정
    func configureInputValidation() {
        nameTextField.delegate = self
    }

    func bind() {
        let confirmRelay = PublishRelay<Void>()
        let deleteConfirmedRelay = PublishRelay<Void>()

        let input = CategoryEditDetailViewModel.Input(
            nameText: nameTextField.rx.text.asObservable(),
            iconNameSelected: iconNameSelectedRelay.asObservable(),
            confirmTapped: confirmRelay.asObservable(),
            deleteTapped: deleteConfirmedRelay.asObservable()
        )

        let output = viewModel.transform(input)

        output.completed
            .bind(onNext: { [weak self] in
                guard let self else { return }
                self.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)

        /// 생성/수정 버튼 선택
        confirmButton.rx.tap
            .bind(onNext: { [weak self] in
                guard let self else { return }

                let name = self.nameTextField.text?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                guard !name.isEmpty else {
                    self.presentEmptyNameAlert()
                    return
                }

                confirmRelay.accept(())
            })
            .disposed(by: disposeBag)

        /// 삭제 버튼 선택
        let deleteTapped = deleteButton.rx.tap
            .flatMapLatest { [weak self] _ -> Observable<AlertController.Action> in
                guard let self else { return .empty() }
                
                return AlertController.rx.alert(
                    on: self,
                    image: UIImage(named: "alertRed") ?? UIImage(),
                    title: "분류 삭제",
                    message: "분류를 삭제하시겠습니까?",
                    actions: [
                        .cancel("취소"),
                        .destructive("삭제")
                    ]
                )
                .asObservable()
            }
            .filter { $0.title == "삭제" }
            .map { _ in }
            .asObservable()
        
        deleteTapped
            .bind(to: deleteConfirmedRelay)
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

//MARK: - UITextFieldDelegate
extension CategoryEditDetailViewController: UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        guard textField == nameTextField else { return true }

        let currentText = textField.text ?? ""
        let updatedText = (currentText as NSString).replacingCharacters(
            in: range,
            with: string
        )

        return updatedText.count <= InputLimit.categoryName
    }
}

//MARK: - Present
private extension CategoryEditDetailViewController {
    /// 이름 미입력 경고 표시
    func presentEmptyNameAlert() {
        let viewController = AlertController(
            image: UIImage(named: "alartRed") ?? UIImage(),
            title: "분류 이름 입력",
            message: "분류 이름을 입력해주세요.",
            actions: [
                .default("확인")
            ]
        )

        present(viewController, animated: true)
    }

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
    /// 키보드 닫기 설정
    func configureKeyboardDismiss() {
        let tap = UITapGestureRecognizer()
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        tap.rx.event
            .bind(onNext: { [weak self] _ in
                self?.view.endEditing(true)
            })
            .disposed(by: disposeBag)
    }

    /// 네비게이션 바 설정
    func configureNavigationBar() {
        title = mode.navigationTitle
        navigationController?.navigationBar.tintColor = .gray800
    }

    /// 데이터 설정
    func configureData() {
        guard let item = mode.item else {
            selectedIconName = nil
            deleteButton.isHidden = true
            return
        }

        selectedIconName = item.iconName
        categoryImageView.image = item.image
        nameTextField.text = item.title
        deleteButton.isHidden = false
        deleteButton.isEnabled = item.userId != nil
    }

    /// UI 설정
    func configureUI() {
        view.keyboardLayoutGuide.usesBottomSafeArea = true
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

        configureBottomButtonConstraints()
    }
    
    /// 하단 버튼 제약 설정
    func configureBottomButtonConstraints() {
        switch mode {
        case .add:
            confirmButton.snp.makeConstraints {
                $0.leading.equalToSuperview().offset(16)
                $0.trailing.equalToSuperview().inset(16)
                $0.bottom.equalTo(view.keyboardLayoutGuide.snp.top).offset(-16)
                $0.height.equalTo(44)
            }
            
        case .edit:
            deleteButton.snp.makeConstraints {
                $0.leading.equalToSuperview().offset(24)
                $0.bottom.equalTo(view.keyboardLayoutGuide.snp.top).offset(-16)
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
}
