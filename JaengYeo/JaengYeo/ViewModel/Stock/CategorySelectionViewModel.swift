//
//  CategorySelectionViewModel.swift
//  JaengYeo
//
//  Created by Codex on 4/12/26.
//

import Foundation
import RxRelay
import RxSwift
import UIKit

struct CategorySelectionItem: Hashable {
    let id: String
    let title: String
    let image: UIImage?
    let isSelect: Bool
}

final class CategorySelectionViewModel: ViewModelProtocol {

    private let disposeBag = DisposeBag()
    private let items: [CategorySelectionItem]
    private let selectedItemIDsRelay = BehaviorRelay<Set<String>>(value: [])

    init(items: [CategorySelectionItem]) {
        self.items = items
        let selectedItemIDs = Set(items.filter { $0.isSelect }.map { $0.id })
        selectedItemIDsRelay.accept(selectedItemIDs)
    }

    struct Input {
        let itemSelectionToggled: Observable<CategorySelectionItem>
        let resetTapped: Observable<Void>
        let applyTapped: Observable<Void>
    }

    struct Output {
        let items: Observable<[CategorySelectionItem]>
        let applyButtonTitle: Observable<String>
        let appliedItemIDs: Observable<[String]>
    }

    func transform(_ input: Input) -> Output {
        let appliedItemIDsRelay = PublishRelay<[String]>()

        input.itemSelectionToggled
            .subscribe(onNext: { [weak self] item in
                self?.toggleSelection(item)
            })
            .disposed(by: disposeBag)

        input.resetTapped
            .subscribe(onNext: { [weak self] in
                self?.selectedItemIDsRelay.accept([])
            })
            .disposed(by: disposeBag)

        input.applyTapped
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                let selectedIDs = self.selectedItemIDsRelay.value
                let orderedSelectedIDs = self.items
                    .map { $0.id }
                    .filter { selectedIDs.contains($0) }

                appliedItemIDsRelay.accept(orderedSelectedIDs)
            })
            .disposed(by: disposeBag)

        let applyButtonTitle = selectedItemIDsRelay
            .map { "\($0.count)개 필터 적용" }
            .asObservable()

        let items = selectedItemIDsRelay
            .map { [items] selectedIDs in
                items.map {
                    CategorySelectionItem(
                        id: $0.id,
                        title: $0.title,
                        image: $0.image,
                        isSelect: selectedIDs.contains($0.id)
                    )
                }
            }
            .asObservable()

        return Output(
            items: items,
            applyButtonTitle: applyButtonTitle,
            appliedItemIDs: appliedItemIDsRelay.asObservable()
        )
    }
}

private extension CategorySelectionViewModel {
    func toggleSelection(_ item: CategorySelectionItem) {
        var selectedIDs = selectedItemIDsRelay.value

        if selectedIDs.contains(item.id) {
            selectedIDs.remove(item.id)
        } else {
            selectedIDs.insert(item.id)
        }

        selectedItemIDsRelay.accept(selectedIDs)
    }
}
