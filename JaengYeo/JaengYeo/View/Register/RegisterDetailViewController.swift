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
    func didTapConfirmButton(item: RegisterFormData)
    func didTapMidCategory(midCategory: UUID?)
    func didTapSubCategory(subCategory: UUID?)
}

final class RegisterDetailViewController: UIViewController {
    
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
    private let fieldsSelectedRelay = PublishRelay<Set<RegisterOptionField>>()
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
        bind()
        
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
}

extension RegisterDetailViewController {
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
        fieldsSelectedRelay.accept(item.selectedFields)
        if let image = item.image {
            mainView.photoButton.setImage(image, for: .normal)
            mainView.photoButton.imageView?.contentMode = .scaleAspectFill
            mainView.photoButton.clipsToBounds = true
            mainView.photoButton.layer.cornerRadius = 8
        }
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
        
        output.selectedFields
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] fields in
                guard let self else { return }
                mainView.subCategoryGroupView.isHidden = !fields.contains(.subCategory)
                mainView.photoGroupView.isHidden = !fields.contains(.photo)
                mainView.expiryDateGroupView.isHidden = !fields.contains(.expiryDate)
                mainView.cautionGroupView.isHidden = !fields.contains(.caution)
                mainView.brandGroupView.isHidden = !fields.contains(.brand)
                mainView.stockAlertGroupView.isHidden = !fields.contains(.stockAlert)
                mainView.memoGroupView.isHidden = !fields.contains(.memo)
            })
            .disposed(by: disposeBag)
        
        output.stockAlertValue
            .observe(on: MainScheduler.instance)
            .bind(to: mainView.stockAlertLabel.rx.text)
            .disposed(by: disposeBag)
        
        output.didConfirm
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] item in
                self?.delegate?.didTapConfirmButton(item: item)
                self?.navigationController?.popViewController(animated: true)
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
        
        mainView.addInfoButton.rx.tap
            .bind(onNext: { [weak self] in
                self?.presentExtraField()
            })
            .disposed(by: disposeBag)
        
        mainView.photoButton.rx.tap
            .bind(onNext: { [weak self] in
                self?.presentImagePicker()
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

        bindDeleteButtons()
    }

    private func bindDeleteButtons() {
        let deleteBindings: [(UIButton, RegisterOptionField)] = [
            (mainView.subCategoryDeleteButton, .subCategory),
            (mainView.photoDeleteButton, .photo),
            (mainView.expiryDateDeleteButton, .expiryDate),
            (mainView.cautionDeleteButton, .caution),
            (mainView.brandDeleteButton, .brand),
            (mainView.stockAlertDeleteButton, .stockAlert),
            (mainView.memoDeleteButton, .memo)
        ]
        deleteBindings.forEach { button, field in
            button.rx.tap
                .bind(onNext: { [weak self] in
                    guard let self else { return }
                    clearFields([field])
                    var fields = viewModel.currentFields
                    fields.remove(field)
                    fieldsSelectedRelay.accept(fields)
                })
                .disposed(by: disposeBag)
        }
    }
}

extension RegisterDetailViewController {
    private func presentExtraField() {
        let sheet = RegisterFieldSelectViewController(selectedFields: viewModel.currentFields)
        sheet.delegate = self
        present(sheet, animated: false)
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

extension RegisterDetailViewController: RegisterFieldSelectViewControllerDelegate {
    func didSelect(fields: Set<RegisterOptionField>) {
        let removed = viewModel.currentFields.subtracting(fields)
        clearFields(removed)
        fieldsSelectedRelay.accept(fields)
    }

    private func clearFields(_ fields: Set<RegisterOptionField>) {
        for field in fields {
            switch field {
            case .subCategory:
                mainView.subCategoryField.text = nil
                subCategorySelectedRelay.accept(nil)
                subCategoryIconNameRelay.accept(nil)
            case .expiryDate:
                mainView.expiryDateField.text = nil
            case .caution:
                mainView.cautionField.text = nil
            case .brand:
                mainView.brandField.text = nil
            case .memo:
                mainView.memoField.text = nil
            case .photo:
                imageClearedRelay.accept(())
            case .stockAlert:
                stockAlertClearedRelay.accept(())
            }
        }
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
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

extension RegisterDetailViewController {
    private func presentImagePicker() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
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
