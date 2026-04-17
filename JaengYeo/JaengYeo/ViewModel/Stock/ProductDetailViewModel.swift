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
// TODO: 추후 ViewModel로 이관예정
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

    
    private var productFetchResultController: NSFetchedResultsController<ProductEntity>?
    
    private let productRelay = BehaviorRelay<Product?>(value: nil)
    private let midCategoryRelay = BehaviorRelay<MidCategory?>(value: nil)
    private let subCategoryRelay = BehaviorRelay<SubCategory?>(value: nil)
    private let displayModelRelay = BehaviorRelay<ProductDetailDisplayModel?>(value: nil)

    
    struct Input {
        let viewDidLoad: Observable<Void>
    }
    
    struct Output {
        let viewUpdate: Observable<ProductDetailDisplayModel>
    }
    
    func transform(_ input: Input) -> Output {
        
        input.viewDidLoad
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                self.configureProductFetchResultController(id: productID)
                self.performFetch()
            })
            .disposed(by: disposeBag)
        
        return Output(
            viewUpdate: displayModelRelay
                .compactMap { $0 }
                .asObservable()
        )
    }
    
    init(productID: UUID, coreDataManager: CoreDataManagerProtocol){
        self.productID = productID
        self.coreDataManager = coreDataManager
        super.init()
    }
}


    extension ProductDetailViewModel: NSFetchedResultsControllerDelegate  {
        private func configureProductFetchResultController(id: UUID){
            let request = ProductEntity.fetchRequest()
            request.sortDescriptors = [
                NSSortDescriptor(
                    key: ProductEntity.Keys.createdAt,
                    ascending: false
                )
            ]
            request.fetchLimit = 1
            request.predicate = NSPredicate(
                format: "%K == %@",
                ProductEntity.Keys.id,
                id as CVarArg
            )

            let controller = NSFetchedResultsController(
                fetchRequest: request,
                managedObjectContext: coreDataManager.context,
                sectionNameKeyPath: nil,
                cacheName: nil
            )

        controller.delegate = self
        productFetchResultController = controller
    }
    
    private func performFetch() {
        do {
            try productFetchResultController?.performFetch()
            updateProductDetail()
        } catch {
            productRelay.accept(nil)
            midCategoryRelay.accept(nil)
            subCategoryRelay.accept(nil)
            displayModelRelay.accept(makeNotFoundDisplayModel())
        }
    }
    
    private func updateProductDetail() {
        guard let productEntity = productFetchResultController?.fetchedObjects?.first else {
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
    
    func fetchMidCategory(id: UUID) -> MidCategory? {
           let request: NSFetchRequest<MidCategoryEntity> = MidCategoryEntity.fetchRequest()
           request.fetchLimit = 1
           request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

           do {
               guard let midEntity = try coreDataManager.context.fetch(request).first else { return nil }
               return midEntity.toDomain
               
           } catch {
               return nil
           }
       }

       func fetchSubCategory(id: UUID) -> SubCategory? {
           let request: NSFetchRequest<SubCategoryEntity> = SubCategoryEntity.fetchRequest()
           request.fetchLimit = 1
           request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

           do {
               guard let subEntity = try coreDataManager.context.fetch(request).first else { return nil }
               return subEntity.toDomain
           } catch {
               return nil
           }
       }
    
    func controllerDidChangeContent(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>
    ) {
        if controller == productFetchResultController {
            updateProductDetail()
        }
    }
}

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
                title: "중분류",
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
                    title: "소분류 (종류)",
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
           product.lowStockThreshold > 0 {
            subInfos.append(
                ProductDetailInfoItem(
                    icon: UIImage(named: ProductInfoIcon.lowStockThresholdIcon.rawValue),
                    title: "알림 재고 수량",
                    detail: "\(product.lowStockThreshold)"
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
