//
//  NSFetchedResultsController+Rx.swift
//  JaengYeo
//
//  Created by 정재성 on 4/22/26.
//

import CoreData
import RxSwift

final class RxFetchedResultsControllerDelegate<ResultType: NSFetchRequestResult>:
    NSObject,
    NSFetchedResultsControllerDelegate {

    let didChangeContentSubject = PublishSubject<[ResultType]>()

    func controllerDidChangeContent(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>
    ) {
        guard
            let typedController = controller as? NSFetchedResultsController<ResultType>
        else { return }

        didChangeContentSubject.onNext(typedController.fetchedObjects ?? [])
    }
}

final class RxFetchedResultsController<ResultType: NSFetchRequestResult> {

    private let fetchedResultsController: NSFetchedResultsController<ResultType>
    private let delegate = RxFetchedResultsControllerDelegate<ResultType>()

    init(
        fetchRequest: NSFetchRequest<ResultType>,
        managedObjectContext: NSManagedObjectContext
    ) {
        self.fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        self.fetchedResultsController.delegate = delegate
    }

    var didChangeContent: Observable<[ResultType]> {
        Observable.create { [fetchedResultsController, delegate] observer in
            do {
                try fetchedResultsController.performFetch()
                observer.onNext(fetchedResultsController.fetchedObjects ?? [])
            } catch {
                observer.onError(error)
            }

            let disposable = delegate.didChangeContentSubject
                .subscribe(observer)

            return Disposables.create {
                disposable.dispose()
                fetchedResultsController.delegate = nil
            }
        }
    }
}
