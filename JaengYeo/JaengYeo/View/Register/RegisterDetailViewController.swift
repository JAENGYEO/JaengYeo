//
//  RegisterDetailViewController.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/12/26.
//

import UIKit
import RxSwift
import RxCocoa

protocol RegisterDetailViewControllerDelegate: AnyObject {
    func didTapConfirmButton(item: RegisterFormData)
}

final class RegisterDetailViewController: UIViewController {
    
    weak var delegate: RegisterDetailViewControllerDelegate?
    
    private let disposeBag = DisposeBag()
    
    private let mainView = RegisterDetailView()
    
    private let viewModel: RegisterDetailViewModel
    private let fieldsSelectedRelay = PublishRelay<Set<RegisterOptionField>>()
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
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
        mainView.locationField.text = item.locationMemo
        mainView.expiryDateField.text = item.expiryDate.map { dateFormatter.string(from: $0) }
        mainView.memoField.text = item.memo
        mainView.cautionField.text = item.caution
        mainView.brandField.text = item.brand
        mainView.stockAlertLabel.text = item.lowStockThreshold.map { String($0) } ?? "0"
        fieldsSelectedRelay.accept(item.selectedFields)
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
                item.locationMemo = mainView.locationField.text.flatMap { $0.isEmpty ? nil : $0 }
                item.purchaseDate = dateFormatter.date(from: mainView.purchaseDateField.text ?? "")
                item.expiryDate = dateFormatter.date(from: mainView.expiryDateField.text ?? "")
                item.memo = mainView.memoField.text.flatMap { $0.isEmpty ? nil : $0 }
                item.caution = mainView.cautionField.text.flatMap { $0.isEmpty ? nil : $0 }
                item.brand = mainView.brandField.text.flatMap { $0.isEmpty ? nil : $0 }
                return item
            }
            .asObservable()
        
        let input = RegisterDetailViewModel.Input(
            foodCategoryTapped: mainView.foodButton.rx.tap.asObservable(),
            householdCategoryTapped: mainView.householdButton.rx.tap.asObservable(),
            fieldsSelected: fieldsSelectedRelay.asObservable(),
            stockPlusTapped: mainView.stockPlusButton.rx.tap.asObservable(),
            stockMinusTapped: mainView.stockMinusButton.rx.tap.asObservable(),
            confirmTapped: confirmTapped
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
        
        mainView.addInfoButton.rx.tap
            .bind(onNext: { [weak self] in
                self?.presentExtraField()
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
        fieldsSelectedRelay.accept(fields)
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
