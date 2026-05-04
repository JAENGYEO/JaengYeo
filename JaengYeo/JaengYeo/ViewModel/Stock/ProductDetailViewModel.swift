//
//  ProductDetailViewModel.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/16/26.
//


import Foundation
import CoreData
import UIKit
import RxSwift
import RxRelay

/// 상세화면 전용 구조체
struct ProductDetailDisplayModel {
    let headerImage: UIImage?
    let productName: String
    let productCount: String

    let mainInfos: [ProductDetailInfoItem]
    let subInfos: [ProductDetailInfoItem]
}

struct ProductDetailInfoItem {
    let icon: UIImage?
    let title: String
    let detail: String
}

final class ProductDetailViewModel: NSObject, ViewModelProtocol {
   
    //MARK: - Properties
    /// 메모리 해제 가방
    private let disposeBag = DisposeBag()
    
    /// 상품
    private let productID: UUID
    
    /// CoreData 매니저
    private let coreDataManager: CoreDataManagerProtocol
    private var productObservationDisposeBag = DisposeBag()
    
    private let productRelay = BehaviorRelay<Product?>(value: nil)
    private let midCategoryRelay = BehaviorRelay<MidCategory?>(value: nil)
    private let subCategoryRelay = BehaviorRelay<SubCategory?>(value: nil)
    private let displayModelRelay = BehaviorRelay<ProductDetailDisplayModel?>(value: nil)
    private let deleteRelay = BehaviorRelay<Bool>(value: false)

    
    struct Input {
        let viewDidLoad: Observable<Void>
        let viewWillAppear: Observable<Void>
        let modifyTapped: Observable<Void>
        let deleteTapped: Observable<Void>
        let addToCartTapped: Observable<Void>
    }

    struct Output {
        let viewUpdate: Observable<ProductDetailDisplayModel>
        let deleteSuccess: Observable<Bool>
        let modify: Observable<(formData: RegisterFormData, originalPayload: ProductPayload)>
        let addToCartSuccess: Observable<Void>
    }
    
    func transform(_ input: Input) -> Output {
        let modifyData = Observable.combineLatest(
            productRelay.compactMap { $0 },
            midCategoryRelay.asObservable(),
            subCategoryRelay.asObservable()
        )
        .map { [weak self] product, midCategory, subCategory in
            self?.makeModifyData(
                product: product,
                midCategory: midCategory,
                subCategory: subCategory
            )
        }
        .compactMap { $0 }

        let addToCartSuccessSubject = PublishSubject<Void>()

        Observable.merge(input.viewDidLoad, input.viewWillAppear)
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                self.bindProduct()
            })
            .disposed(by: disposeBag)

        input.deleteTapped
            .subscribe(onNext: { [weak self] _ in
                guard let self else { return }
                let ok = (try? self.coreDataManager.softDeleteProduct(id: self.productID)) != nil
                self.deleteRelay.accept(ok)
            })
            .disposed(by: disposeBag)

        input.addToCartTapped
            .withLatestFrom(productRelay.compactMap { $0 })
            .subscribe(onNext: { [weak self] product in
                guard let self else { return }
                let payload = CartItemPayload(
                    id: UUID(),
                    referenceId: product.id,
                    name: product.name,
                    mainCategory: product.mainCategory,
                    quantity: 1,
                    createdAt: Date()
                )
                try? self.coreDataManager.createCartItem(payload)
                addToCartSuccessSubject.onNext(())
            })
            .disposed(by: disposeBag)

        return Output(
            viewUpdate: displayModelRelay
                .compactMap { $0 },
            deleteSuccess: deleteRelay
                .skip(1)
                .asObservable(),
            modify: input.modifyTapped
                .withLatestFrom(modifyData),
            addToCartSuccess: addToCartSuccessSubject.asObservable()
        )
    }
    
    init(productID: UUID, coreDataManager: CoreDataManagerProtocol){
        self.productID = productID
        self.coreDataManager = coreDataManager
        super.init()
    }
}


// MARK: - CoreData Stream
private extension ProductDetailViewModel {
    func bindProduct() {
        productObservationDisposeBag = DisposeBag()

        coreDataManager.observeProducts(
            predicate: makeProductPredicate(id: productID),
            sortDescriptors: [
                NSSortDescriptor(
                    key: ProductEntity.Keys.createdAt,
                    ascending: false
                )
            ]
        )
        .subscribe(
            onNext: { [weak self] products in
                self?.updateProductDetail(productEntity: products.first)
            },
            onError: { [weak self] _ in
                self?.productRelay.accept(nil)
                self?.midCategoryRelay.accept(nil)
                self?.subCategoryRelay.accept(nil)
                self?.displayModelRelay.accept(self?.makeNotFoundDisplayModel())
            }
        )
        .disposed(by: productObservationDisposeBag)
    }

    func updateProductDetail(productEntity: ProductEntity?) {
        guard let productEntity else {
            productRelay.accept(nil)
            midCategoryRelay.accept(nil)
            subCategoryRelay.accept(nil)
            displayModelRelay.accept(makeNotFoundDisplayModel())
            return
        }

        let product = productEntity.toDomain
        productRelay.accept(product)

        let midCategory = product.midCategoryId.flatMap { fetchMidCategory(id: $0) }
        let subCategory = product.subCategoryId.flatMap { fetchSubCategory(id: $0) }

        midCategoryRelay.accept(midCategory)
        subCategoryRelay.accept(subCategory)

        let displayModel = makeDisplayModel(
            product: product,
            midCategory: midCategory,
            subCategory: subCategory
        )
        displayModelRelay.accept(displayModel)
    }
    
    func makeProductPredicate(id: UUID) -> NSPredicate {
        NSPredicate(
            format: "%K == %@",
            ProductEntity.Keys.id,
            id as CVarArg
        )
    }

    func fetchMidCategory(id: UUID) -> MidCategory? {
        try? coreDataManager.fetchMidCategory(of: id).toDomain()
    }

    func fetchSubCategory(id: UUID) -> SubCategory? {
        try? coreDataManager.fetchSubCategory(of: id).toDomain()
    }
}

//MARK: - Action
private extension ProductDetailViewModel {
    private func makeModifyData(
        product: Product,
        midCategory: MidCategory?,
        subCategory: SubCategory?
    ) -> (formData: RegisterFormData, originalPayload: ProductPayload) {
        let payload = product.toPayload()
        let formData = payload.toRegisterFormData(
            midCategoryName: midCategory?.name,
            subCategoryData: subCategory?.toPayload()
        )

        return (
            formData: formData,
            originalPayload: payload
        )
    }
}


//MARK: - Create Display Model
private extension ProductDetailViewModel {
    func makeNotFoundDisplayModel() -> ProductDetailDisplayModel {
        ProductDetailDisplayModel(
            headerImage: UIImage(named: "iconSelectIcon"),
            productName: "상품을 불러오지 못했어요",
            productCount: "-",
            mainInfos: [],
            subInfos: []
        )
    }

    func makeDisplayModel(
        product: Product,
        midCategory: MidCategory?,
        subCategory: SubCategory?
    ) -> ProductDetailDisplayModel {
        let headerImage: UIImage? = {
            if let fileName = product.imageUrl,
               let image = ImageUtils.loadImage(fileName: fileName) {
                return image
            }

            if let iconName = subCategory?.iconName {
                return UIImage(named: iconName)
            }

            return UIImage(named: "iconSelectIcon")
        }()

        let mainInfos: [ProductDetailInfoItem] = [
            ProductDetailInfoItem(
                icon: UIImage(named: ProductInfoIcon.mainCategoryIcon.rawValue),
                title: "대분류",
                detail: product.mainCategory
            ),
            ProductDetailInfoItem(
                icon: UIImage(named: ProductInfoIcon.midCategoryIcon.rawValue),
                title: "보관 위치",
                detail: midCategory?.name ?? "-"
            ),
            ProductDetailInfoItem(
                icon: UIImage(named: ProductInfoIcon.purchaseDateIcon.rawValue),
                title: "등록일",
                detail: formatDate(product.createdAt)
            )
        ]

        var subInfos: [ProductDetailInfoItem] = []

        if let subCategory {
            subInfos.append(
                ProductDetailInfoItem(
                    icon: UIImage(named: ProductInfoIcon.subCategoryIcon.rawValue),
                    title: "종류",
                    detail: subCategory.name
                )
            )
        }

        if let expiryDate = product.expiryDate {
            subInfos.append(
                ProductDetailInfoItem(
                    icon: UIImage(named: ProductInfoIcon.expiryDateIcon.rawValue),
                    title: "소비기한",
                    detail: formatDate(expiryDate)
                )
            )
        }


        if let caution = product.caution, !caution.isEmpty {
            subInfos.append(
                ProductDetailInfoItem(
                    icon: UIImage(named: ProductInfoIcon.cautionIcon.rawValue),
                    title: "유의사항/취급 주의사항",
                    detail: caution
                )
            )
        }

        if let brand = product.brand, !brand.isEmpty {
            subInfos.append(
                ProductDetailInfoItem(
                    icon: UIImage(named: ProductInfoIcon.brandIcon.rawValue),
                    title: "브랜드",
                    detail: brand
                )
            )
        }

        if product.isLowStockNotificationEnabled,
           let threshold = product.lowStockThreshold, threshold > 0 {
            subInfos.append(
                ProductDetailInfoItem(
                    icon: UIImage(named: ProductInfoIcon.lowStockThresholdIcon.rawValue),
                    title: "알림 재고 수량",
                    detail: "\(threshold)"
                )
            )
        }

        if let memo = product.memo, !memo.isEmpty {
            subInfos.append(
                ProductDetailInfoItem(
                    icon: UIImage(named: ProductInfoIcon.memoIcon.rawValue),
                    title: "메모",
                    detail: memo
                )
            )
        }
         
        return ProductDetailDisplayModel(
            headerImage: headerImage,
            productName: product.name,
            productCount: "\(product.quantity)",
            mainInfos: mainInfos,
            subInfos: subInfos
        )
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }
}
