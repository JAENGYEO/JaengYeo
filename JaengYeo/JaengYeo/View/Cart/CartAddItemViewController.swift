//
//  CartAddItemViewController.swift
//  JaengYeo
//
//  Created by Hanjuheon on 5/3/26.
//

import RxCocoa
import RxSwift
import UIKit

final class CartAddItemViewController: BaseViewController {

    //MARK: - Input Limit
    private enum InputLimit {
        static let productName = 20
        static let quantity = 999
    }

    //MARK: - Properties
    override var handlesKeyboardInset: Bool { false }

    private let disposeBag = DisposeBag()
    private let viewModel: CartAddItemViewModel

    //MARK: - Components
    private let mainView = CartAddItemView()

    //MARK: - Init
    init(viewModel: CartAddItemViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = mainView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureMode()
        restoreFields()
        configureInputValidation()
        bind()
    }
}

//MARK: - Binding
extension CartAddItemViewController {
    func bind() {
        let confirmTapped = mainView.saveButton.rx.tap
            .map { [weak self] in
                CartAddItemFormData(
                    name: self?.mainView.nameField.text?.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ) ?? "",
                    quantity: self?.mainView.quantityField.text.flatMap { Int($0) }
                )
            }
            .asObservable()

        let deleteTapped = mainView.deleteButton.rx.tap
            .flatMapLatest { [weak self] _ in
                AlertController.rx.alert(
                    on: self,
                    image: UIImage(named: "alertRed") ?? UIImage(),
                    title: "항목 삭제",
                    message: "장바구니 항목을 삭제하시겠습니까?",
                    actions: [
                        .cancel("취소"),
                        .destructive("삭제")
                    ]
                )
            }
            .filter { $0.title == "삭제" }
            .map { _ in }
            .asObservable()

        let input = CartAddItemViewModel.Input(
            foodCategoryTapped: mainView.foodButton.rx.tap.asObservable(),
            householdCategoryTapped: mainView.householdButton.rx.tap.asObservable(),
            confirmTapped: confirmTapped,
            deleteTapped: deleteTapped
        )

        let output = viewModel.transform(input)

        output.selectedCategory
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] category in
                self?.mainView.updateCategoryButtons(selected: category)
            })
            .disposed(by: disposeBag)

        output.confirmError
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] message in
                self?.showErrorAlert(message)
            })
            .disposed(by: disposeBag)

        output.didConfirm
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)

        output.didDelete
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)

        output.error
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] message in
                self?.showErrorAlert(message)
            })
            .disposed(by: disposeBag)
    }
}

//MARK: - Configure
extension CartAddItemViewController {
    func configureNavigationBar() {
        navigationItem.title = viewModel.navigationTitle

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .font: LabelConfiguration.titleSemi18.font,
            .foregroundColor: UIColor.gray800
        ]

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .gray800
    }

    func configureInputValidation() {
        mainView.nameField.delegate = self
        mainView.quantityField.delegate = self
    }

    func configureMode() {
        mainView.updateMode(isEdit: viewModel.isEditMode)
    }
}

//MARK: - Action
private extension CartAddItemViewController {
    func restoreFields() {
        guard let item = viewModel.item else { return }

        mainView.nameField.text = item.name
        mainView.quantityField.text = String(item.quantity)
    }

    func showErrorAlert(_ message: String) {
        let alert = AlertController(
            image: .warningIcon,
            title: "입력 확인",
            message: message,
            actions: [.default("확인")]
        )
        present(alert, animated: true)
    }
}

//MARK: - UITextFieldDelegate
extension CartAddItemViewController: UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        if textField == mainView.nameField {
            return validateTextLength(
                currentText: textField.text,
                range: range,
                replacementString: string,
                maxLength: InputLimit.productName
            )
        }

        if textField == mainView.quantityField {
            return validateNumericInput(
                currentText: textField.text,
                range: range,
                replacementString: string
            )
        }

        return true
    }

    func validateTextLength(
        currentText: String?,
        range: NSRange,
        replacementString string: String,
        maxLength: Int
    ) -> Bool {
        guard let currentText else {
            return string.count <= maxLength
        }

        let updatedText = (currentText as NSString).replacingCharacters(
            in: range,
            with: string
        )

        return updatedText.count <= maxLength
    }

    func validateNumericInput(
        currentText: String?,
        range: NSRange,
        replacementString string: String
    ) -> Bool {
        if string.isEmpty {
            return true
        }

        if string.count > 1 {
            return false
        }

        let allowedCharacterSet = CharacterSet.decimalDigits
        guard string.rangeOfCharacter(from: allowedCharacterSet.inverted) == nil else {
            return false
        }

        guard let currentText else {
            return true
        }

        let updatedText = (currentText as NSString).replacingCharacters(
            in: range,
            with: string
        )

        guard let value = Int(updatedText) else {
            return false
        }

        return value <= InputLimit.quantity
    }
}

#Preview {
    BaseNavigationController(
        rootViewController: CartAddItemViewController(
            viewModel: CartAddItemViewModel(
                coreDataManager: CoreDataManager()
            )
        )
    )
}
