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
    
    private var item: RegisterFormData
    
    private let disposeBag = DisposeBag()
    
    private let mainView = RegisterDetailView()
    private var selectedCategory: RegisterDetailView.CategoryType?
    
    private var selectedFields: Set<RegisterOptionField> = []
    
    init(item: RegisterFormData) {
        self.item = item
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
        bind()
        
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
}

extension RegisterDetailViewController {
    private func configNavigationBar() {
        navigationItem.title = item.name ?? "상세 입력"
        let appearance = UINavigationBarAppearance()
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.gray800,
            .font: LabelConfiguration.titleSemi18.font
        ]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
}

extension RegisterDetailViewController {
    private func bind() {
        
        Observable.just(item)
            .bind(onNext: { [weak self] item in
                guard let self else { return }
                mainView.nameField.text = item.name
                mainView.quantityField.text = item.quantity.map { String($0) }
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                mainView.purchaseDateField.text = formatter.string(from: item.purchaseDate ?? Date())
                switch item.mainCategory {
                case "식재료": selectedCategory = .food
                case "생활용품": selectedCategory = .household
                default: selectedCategory = nil
                }
                mainView.updateCategoryButtons(selected: selectedCategory)
                mainView.locationField.text = item.locationMemo
                mainView.subCategoryField.text = item.subCategory
                mainView.expiryDateField.text = item.expiryDate.map { formatter.string(from: $0) }
                mainView.memoField.text = item.memo
                mainView.cautionField.text = item.caution
                mainView.brandField.text = item.brand
                mainView.stockAlertLabel.text = item.lowStockThreshold.map { String($0)} ?? "0"
                didSelect(fields: item.selectedFields)
            })
            .disposed(by: disposeBag)
        
        mainView.foodButton.rx.tap
            .bind(onNext: { [weak self] in
                guard let self else { return }
                selectedCategory = .food
                mainView.updateCategoryButtons(selected: .food)
            })
            .disposed(by: disposeBag)
        
        mainView.householdButton.rx.tap
            .bind(onNext: { [weak self] in
                guard let self else { return }
                selectedCategory = .household
                mainView.updateCategoryButtons(selected: .household)
            })
            .disposed(by: disposeBag)
        
        mainView.addInfoButton.rx.tap
            .bind(onNext: { [weak self] in
                guard let self else { return }
                self.presentExtraField()
            })
            .disposed(by: disposeBag)
        
        mainView.stockMinusButton.rx.tap
            .bind(onNext: { [weak self] in
                guard let self,
                      let text = mainView.stockAlertLabel.text,
                      let value = Int(text), value > 0 else { return }
                mainView.stockAlertLabel.text = "\(value - 1)"
            })
            .disposed(by: disposeBag)
        
        mainView.stockPlusButton.rx.tap
            .bind(onNext: { [weak self] in
                guard let self,
                      let text = mainView.stockAlertLabel.text,
                      let value = Int(text) else { return }
                mainView.stockAlertLabel.text = "\(value + 1)"
            })
            .disposed(by: disposeBag)
        
        mainView.confirmButton.rx.tap
            .bind(onNext: { [weak self] in
                guard let self else { return }
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                
                item.name = mainView.nameField.text.flatMap { $0.isEmpty ? nil : $0 }
                item.quantity = mainView.quantityField.text.flatMap { Int($0) }
                item.mainCategory = selectedCategory == .food ? "식재료" : selectedCategory == .household ? "생활용품" : nil
                item.locationMemo = mainView.locationField.text.flatMap { $0.isEmpty ? nil : $0 }
                item.purchaseDate = formatter.date(from: mainView.purchaseDateField.text ?? "")
                
                if selectedFields.contains(.expiryDate) {
                    item.expiryDate = formatter.date(from: mainView.expiryDateField.text ?? "")
                }
                if selectedFields.contains(.stockAlert) {
                    item.lowStockThreshold = mainView.stockAlertLabel.text.flatMap { Int($0) }
                    item.isLowStockNotificationEnabled = (item.lowStockThreshold ?? 0) > 0
                }
                if selectedFields.contains(.memo) {
                    item.memo = mainView.memoField.text.flatMap { $0.isEmpty ? nil : $0 }
                }
                if selectedFields.contains(.caution) {
                    item.caution = mainView.cautionField.text.flatMap { $0.isEmpty ? nil : $0 }
                }
                if selectedFields.contains(.brand) {
                    item.brand = mainView.brandField.text.flatMap { $0.isEmpty ? nil : $0 }
                }
                
                // name, mainCategory: nil일 경우 저장 x
                guard item.name != nil, item.mainCategory != nil else {
                    return
                }
                item.selectedFields = selectedFields
                delegate?.didTapConfirmButton(item: item)
                navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
    }
}

extension RegisterDetailViewController {
    private func presentExtraField() {
        let sheet = RegisterFieldSelectViewController(selectedFields: selectedFields)
        sheet.delegate = self
        present(sheet, animated: false)
    }
}

extension RegisterDetailViewController: RegisterFieldSelectViewControllerDelegate {
    func didSelect(fields: Set<RegisterOptionField>) {
        selectedFields = fields
        mainView.subCategoryGroupView.isHidden = !fields.contains(.subCategory)
        mainView.photoGroupView.isHidden = !fields.contains(.photo)
        mainView.expiryDateGroupView.isHidden = !fields.contains(.expiryDate)
        mainView.cautionGroupView.isHidden = !fields.contains(.caution)
        mainView.brandGroupView.isHidden = !fields.contains(.brand)
        mainView.stockAlertGroupView.isHidden = !fields.contains(.stockAlert)
        mainView.memoGroupView.isHidden = !fields.contains(.memo)
    }
}
