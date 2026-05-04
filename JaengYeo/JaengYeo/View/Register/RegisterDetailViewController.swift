//
//  RegisterDetailViewController.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/12/26.
//

import UIKit
import RxSwift
import RxCocoa
import PhotosUI

protocol RegisterDetailViewControllerDelegate: AnyObject {
    func didTapConfirmButton(
        _ viewController: RegisterDetailViewController,
        item: RegisterFormData
    )
    func didTapMidCategory(midCategory: UUID?)
    func didTapSubCategory(subCategory: UUID?)
}

final class RegisterDetailViewController: BaseViewController {

    //MARK: - Input Limit
    private enum InputLimit {
        static let productName = 20
        static let brand = 20
        static let caution = 100
        static let memo = 100
        static let quantity = 999
    }

    override var handlesKeyboardInset: Bool { false }

    weak var delegate: RegisterDetailViewControllerDelegate?
    
    private let disposeBag = DisposeBag()
    
    private let mainView = RegisterDetailView()
    var currentMainCategory: String? {
        switch viewModel.currentCategory {
        case .food:
            return "식재료"
        case .household:
            return "생활용품"
        case nil:
            return nil
        }
    }
    
    private let viewModel: RegisterDetailViewModel
    private let fieldsSelectedRelay = BehaviorRelay<Set<RegisterOptionField>>(value: Set(RegisterOptionField.allCases))
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    private let imagePickedSubject = PublishSubject<UIImage>()
    private lazy var midCategorySelectedRelay = BehaviorRelay<UUID?>(value: viewModel.item.midCategory)
    private lazy var subCategorySelectedRelay = BehaviorRelay<UUID?>(value: viewModel.item.subCategory)
    private lazy var subCategoryIconNameRelay = BehaviorRelay<String?>(value: viewModel.item.subCategoryIconName)
    private let imageClearedRelay = PublishRelay<Void>()
    private let stockAlertClearedRelay = PublishRelay<Void>()
    
    init(viewModel: RegisterDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = mainView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configNavigationBar()
        restoreFields()
        configPhotoButton()
        configureInputValidation()
        bind()
    }
}

extension RegisterDetailViewController {
    private func configureInputValidation() {
        mainView.nameField.delegate = self
        mainView.quantityField.delegate = self
        mainView.cautionField.delegate = self
        mainView.brandField.delegate = self
        mainView.memoField.delegate = self
    }

    private func configNavigationBar() {
        navigationItem.title = viewModel.item.name ?? "상세 입력"
        let appearance = UINavigationBarAppearance()
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.gray800,
            .font: LabelConfiguration.titleSemi18.font
        ]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
    private func restoreFields() {
        let item = viewModel.item
        mainView.nameField.text = item.name
        mainView.quantityField.text = item.quantity.map { String($0) }
        mainView.purchaseDateField.text = dateFormatter.string(from: item.purchaseDate ?? Date())
        mainView.midCategoryField.text = item.midCategoryName
        mainView.subCategoryField.text = item.subCategoryName
        mainView.expiryDateField.text = item.expiryDate.map { dateFormatter.string(from: $0) }
        mainView.memoField.text = item.memo
        mainView.cautionField.text = item.caution
        mainView.brandField.text = item.brand
        mainView.stockAlertLabel.text = item.lowStockThreshold.map { String($0) } ?? "0"
        if let image = item.image {
            mainView.photoButton.setImage(image, for: .normal)
            mainView.photoButton.imageView?.contentMode = .scaleAspectFill
            mainView.photoButton.clipsToBounds = true
            mainView.photoButton.layer.cornerRadius = 8
        }
    }
}

//MARK: - UITextFieldDelegate
extension RegisterDetailViewController: UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        if textField == mainView.quantityField {
            return validateNumericInput(
                currentText: textField.text,
                range: range,
                replacementString: string
            )
        }

        if textField == mainView.nameField {
            return validateTextLength(
                currentText: textField.text,
                range: range,
                replacementString: string,
                maxLength: InputLimit.productName
            )
        }

        if textField == mainView.brandField {
            return validateTextLength(
                currentText: textField.text,
                range: range,
                replacementString: string,
                maxLength: InputLimit.brand
            )
        }

        if textField == mainView.cautionField {
            return validateTextLength(
                currentText: textField.text,
                range: range,
                replacementString: string,
                maxLength: InputLimit.caution
            )
        }

        if textField == mainView.memoField {
            return validateTextLength(
                currentText: textField.text,
                range: range,
                replacementString: string,
                maxLength: InputLimit.memo
            )
        }

        return true
    }

    private func validateTextLength(
        currentText: String?,
        range: NSRange,
        replacementString string: String,
        maxLength: Int
    ) -> Bool {
        guard let currentText else { return string.count <= maxLength }

        let updatedText = (currentText as NSString).replacingCharacters(
            in: range,
            with: string
        )
        return updatedText.count <= maxLength
    }

    private func validateNumericInput(
        currentText: String?,
        range: NSRange,
        replacementString string: String
    ) -> Bool {
        if string.isEmpty {
            return true
        }

        // Prevent pasting into numeric-only input.
        if string.count > 1 {
            return false
        }

        let allowedCharacterSet = CharacterSet.decimalDigits
        guard string.rangeOfCharacter(from: allowedCharacterSet.inverted) == nil else {
            return false
        }

        guard let currentText else { return true }
        let updatedText = (currentText as NSString).replacingCharacters(
            in: range,
            with: string
        )
        guard updatedText.rangeOfCharacter(from: allowedCharacterSet.inverted) == nil else {
            return false
        }

        guard let value = Int(updatedText) else {
            return false
        }

        return value <= InputLimit.quantity
    }
}

extension RegisterDetailViewController {
    private func bind() {
        
        let confirmTapped = mainView.confirmButton.rx.tap
            .map { [weak self] _ -> RegisterFormData in
                guard let self else { return RegisterFormData() }
                var item = viewModel.item
                item.name = mainView.nameField.text.flatMap { $0.isEmpty ? nil : $0 }
                item.quantity = mainView.quantityField.text.flatMap { Int($0) }
                item.purchaseDate = dateFormatter.date(from: mainView.purchaseDateField.text ?? "")
                item.expiryDate = dateFormatter.date(from: mainView.expiryDateField.text ?? "")
                item.memo = mainView.memoField.text.flatMap { $0.isEmpty ? nil : $0 }
                item.caution = mainView.cautionField.text.flatMap { $0.isEmpty ? nil : $0 }
                item.brand = mainView.brandField.text.flatMap { $0.isEmpty ? nil : $0 }
                item.midCategoryName = mainView.midCategoryField.text.flatMap { $0.isEmpty ? nil : $0 }
                item.subCategoryName = mainView.subCategoryField.text.flatMap { $0.isEmpty ? nil : $0 }
                item.subCategoryIconName = subCategoryIconNameRelay.value
                return item
            }
            .asObservable()
        
        let midCategoryTap = UITapGestureRecognizer()
        mainView.midCategoryGroupView.isUserInteractionEnabled = true
        mainView.midCategoryGroupView.addGestureRecognizer(midCategoryTap)
        midCategoryTap.rx.event
            .bind(onNext: { [weak self] _ in
                guard let self else { return }
                delegate?.didTapMidCategory(midCategory: midCategorySelectedRelay.value)
            })
            .disposed(by: disposeBag)
        
        let subCategoryTap = UITapGestureRecognizer()
        mainView.subCategoryGroupView.isUserInteractionEnabled = true
        mainView.subCategoryGroupView.addGestureRecognizer(subCategoryTap)
        subCategoryTap.rx.event
            .bind(onNext: { [weak self] _ in
                guard let self else { return }
                delegate?.didTapSubCategory(subCategory: subCategorySelectedRelay.value)
            })
            .disposed(by: disposeBag)
        
        let input = RegisterDetailViewModel.Input(
            foodCategoryTapped: mainView.foodButton.rx.tap.asObservable(),
            householdCategoryTapped: mainView.householdButton.rx.tap.asObservable(),
            fieldsSelected: fieldsSelectedRelay.asObservable(),
            stockPlusTapped: mainView.stockPlusButton.rx.tap.asObservable(),
            stockMinusTapped: mainView.stockMinusButton.rx.tap.asObservable(),
            confirmTapped: confirmTapped,
            imagePicked: imagePickedSubject.asObservable(),
            midCategorySelected: midCategorySelectedRelay.asObservable(),
            subCategorySelected: subCategorySelectedRelay.asObservable(),
            imageCleared: imageClearedRelay.asObservable(),
            stockAlertCleared: stockAlertClearedRelay.asObservable()
        )
        
        let output = viewModel.transform(input)
        
        output.stockAlertValue
            .observe(on: MainScheduler.instance)
            .bind(to: mainView.stockAlertLabel.rx.text)
            .disposed(by: disposeBag)
        
        output.didConfirm
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] item in
                guard let self else { return }
                self.delegate?.didTapConfirmButton(self, item: item)
                self.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
        
        output.selectedCategory
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] category in
                self?.mainView.updateCategoryButtons(selected: category)
            })
            .disposed(by: disposeBag)
        
        output.confirmError
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] error in
                self?.showErrorAlert(title: "에러", message: error)
            })
            .disposed(by: disposeBag)
        
        output.selectedImage
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] image in
                if let image {
                    self?.mainView.photoButton.setImage(image, for: .normal)
                    self?.mainView.photoButton.imageView?.contentMode = .scaleAspectFill
                    self?.mainView.photoButton.clipsToBounds = true
                    self?.mainView.photoButton.layer.cornerRadius = 8
                } else {
                    self?.mainView.photoButton.setImage(UIImage(named: "imageSelectIcon"), for: .normal)
                    self?.mainView.photoButton.imageView?.contentMode = .scaleAspectFill
                    self?.mainView.photoButton.clipsToBounds = false
                    self?.mainView.photoButton.layer.cornerRadius = 0
                }
            })
            .disposed(by: disposeBag)
        
        output.categoryChanged
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] in
                self?.mainView.midCategoryField.text = nil
                self?.mainView.subCategoryField.text = nil
                self?.midCategorySelectedRelay.accept(nil)
                self?.subCategorySelectedRelay.accept(nil)
                self?.subCategoryIconNameRelay.accept(nil)
            })
            .disposed(by: disposeBag)
        
        let purchaseDateTap = UITapGestureRecognizer()
        mainView.purchaseDateGroupView.isUserInteractionEnabled = true
        mainView.purchaseDateGroupView.addGestureRecognizer(purchaseDateTap)
        purchaseDateTap.rx.event
            .bind(onNext: { [weak self] _ in self?.presentDatePicker(type: .purchaseDate) })
            .disposed(by: disposeBag)

        let expiryDateTap = UITapGestureRecognizer()
        mainView.expiryDateGroupView.isUserInteractionEnabled = true
        mainView.expiryDateGroupView.addGestureRecognizer(expiryDateTap)
        expiryDateTap.rx.event
            .bind(onNext: { [weak self] _ in self?.presentDatePicker(type: .expiryDate) })
            .disposed(by: disposeBag)

    }

    private func presentDatePicker(type: DatePickerBottomSheetViewController.DatePickerType) {
        let (title, text): (String, String?) = {
            switch type {
            case .purchaseDate: return ("구매 날짜", mainView.purchaseDateField.text)
            case .expiryDate:   return ("유통기한", mainView.expiryDateField.text)
            }
        }()
        let initialDate = text.flatMap { dateFormatter.date(from: $0) }
        let sheet = DatePickerBottomSheetViewController(sheetTitle: title, initialDate: initialDate)
        sheet.delegate = self
        sheet.datePickerType = type
        present(sheet, animated: false)
    }
}

extension RegisterDetailViewController: DatePickerBottomSheetViewControllerDelegate {
    func datePickerBottomSheet(_ vc: DatePickerBottomSheetViewController, didSelect date: Date) {
        let formatted = dateFormatter.string(from: date)
        switch vc.datePickerType {
        case .purchaseDate: mainView.purchaseDateField.text = formatted
        case .expiryDate: mainView.expiryDateField.text = formatted
        case nil: break
        }
    }
}

extension RegisterDetailViewController {
    private func showErrorAlert(title: String, message: String) {
        let alert = AlertController(
            image: .warningIcon,
            title: title,
            message: message,
            actions: [.default("확인")]
        )
        present(alert, animated: true)
    }
}

extension RegisterDetailViewController {
    private func configPhotoButton() {
        mainView.photoButton.overrideUserInterfaceStyle = .light
        let cameraAction = UIAction(title: "사진 찍기", image: UIImage(systemName: "camera")) { [weak self] _ in
            self?.presentPhotoCamera()
        }
        let albumAction = UIAction(title: "앨범에서 선택", image: UIImage(systemName: "photo.on.rectangle")) { [weak self] _ in
            self?.presentImagePicker()
        }
        mainView.photoButton.menu = UIMenu(children: [cameraAction, albumAction])
        mainView.photoButton.showsMenuAsPrimaryAction = true
            
    }
    
    private func presentImagePicker() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func presentPhotoCamera() {
        let viewController = PhotoCameraViewController()
        viewController.photoCaptured
            .bind(to: imagePickedSubject)
            .disposed(by: disposeBag)
        viewController.modalPresentationStyle = .fullScreen
        present(viewController, animated: true)
    }
}

extension RegisterDetailViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else { return }
        
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let image = object as? UIImage else { return }
            self?.imagePickedSubject.onNext(image)
        }
    }
}

extension RegisterDetailViewController {
    func didSelectMidCategory(id: UUID?, name: String?) {
        mainView.midCategoryField.text = name
        midCategorySelectedRelay.accept(id)
    }
    
    func didSelectSubCategory(id: UUID?, name: String?, iconName: String?) {
        mainView.subCategoryField.text = name
        subCategorySelectedRelay.accept(id)
        subCategoryIconNameRelay.accept(iconName)
    }
}
