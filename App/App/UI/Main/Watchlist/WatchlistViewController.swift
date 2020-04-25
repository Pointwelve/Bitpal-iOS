//
//  WatchlistViewController.swift
//  App
//
//  Created by Hong on 26/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import FirebaseCrashlytics
import Domain
import RxCocoa
import RxDataSources
import RxSwift
import SwiftReorder
import SwipeCellKit
import UIKit

final class WatchlistViewController: UIViewController, DefaultViewControllerType, ScreenNameable {
   fileprivate enum Metric {
      static let rowHeight: CGFloat = 70.0
   }

   typealias ViewModel = WatchlistViewModel

   var disposeBag = DisposeBag()
   var viewModel: WatchlistViewModel!
   var deleteIndexPathSubject = PublishSubject<IndexPath>()
   var fromIndexToIndexSubject = PublishSubject<(IndexPath, IndexPath)>()

   private lazy var loadStateView: LoadStateView = {
      let view = LoadStateView()
      view.translatesAutoresizingMaskIntoConstraints = false
      view.isHidden = true
      return view
   }()

   private let tableViewDataTrigger = BehaviorSubject<Void?>(value: nil)

   fileprivate lazy var tableView: UITableView = {
      let tableView = UITableView()
      tableView.translatesAutoresizingMaskIntoConstraints = false
      tableView.rowHeight = Metric.rowHeight
      tableView.registerCell(of: WatchlistTableViewCell.self, with: WatchlistTableViewCell.identifier)

      return tableView
   }()

   private lazy var addWatchlistBarButton: UIBarButtonItem = {
      let addWatchlistBarButton = UIBarButtonItem(image:
         Image.plusIcon.resource, style: .plain, target: self, action: nil)
      addWatchlistBarButton.tintColor = Color.tealish

      return addWatchlistBarButton
   }()

   private var loadingIndicator: LoadingIndicator = {
      let view = LoadingIndicator()
      view.translatesAutoresizingMaskIntoConstraints = false
      view.isHidden = true

      return view
   }()

   fileprivate var dataSource: RxTableViewSectionedReloadDataSource<WatchlistListData>?

   var screenNameAccessibilityId: AccessibilityIdentifier {
      return .watchlistTitle
   }

   func layout() {
      update(screenName: "watchlist.title".localized())

      let addButton = addWatchlistBarButton
      addButton.setAccessibility(id: .watchlistAddButton)
      navigationItem.rightBarButtonItem = addButton
      [tableView, loadStateView].forEach(view.addSubview)

      NSLayoutConstraint.activate([
         loadStateView.topAnchor.constraint(equalTo: view.topAnchor),
         loadStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
         loadStateView.leftAnchor.constraint(equalTo: view.leftAnchor),
         loadStateView.rightAnchor.constraint(equalTo: view.rightAnchor),

         tableView.topAnchor.constraint(equalTo: view.topAnchor),
         tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
         tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
         tableView.rightAnchor.constraint(equalTo: view.rightAnchor)
      ])

      registerForPreviewing(with: self, sourceView: tableView)
   }

   func bind() {
      tableView.reorder.delegate = self

      // Ended dragging
      let didEndDragging = tableView.rx
         .didEndDragging
         .filter { !$0 }
         .void()

      // Ended decelerating
      let didEndDecelerating = tableView.rx
         .didEndDecelerating
         .asObservable()

      // Get latest visible rows while either event triggers
      let visibleCellRows = Observable.merge(didEndDragging, didEndDecelerating)
         .map { [weak self] _ in
            self?.tableView.indexPathsForVisibleRows?.compactMap { $0.row }
         }.asDriver(onErrorJustReturn: nil)
         .filterNil()
         .distinctUntilChanged {
            let firstSet = Set($0)
            let secondSet = Set($1)
            return firstSet == secondSet
         }

      //
      let didDragToTop = didEndDecelerating.map { [weak self] in
         self?.tableView.indexPathsForVisibleRows?.compactMap { $0.row }
      }
      .asDriver(onErrorJustReturn: nil)
      .filterNil()
      .withLatestFrom(visibleCellRows) { ($0, $1) }
      .filter { $0.0 == $0.1 }
      .map { $0.0 }

      func displayCellDriver() -> Driver<[Int]> {
         return tableView.rx.willDisplayCell.asObservable()
            .filter { (_, indexPath) -> Bool in
               indexPath.row == self.tableView.indexPathsForVisibleRows?.last?.row
            }
            .take(1)
            .map { _ in self.tableView.indexPathsForVisibleRows?.compactMap { $0.row } ?? [] }
            .asDriver(onErrorJustReturn: [])
      }

      // Manaul Triggering from view appear, delete action
      let manualTrigger = tableViewDataTrigger
         .filterNil()
         .asDriver(onErrorJustReturn: ())
         .flatMap { displayCellDriver() }

      let mergedVisibleCells = Driver.merge(didDragToTop, visibleCellRows, manualTrigger).debounce(.milliseconds(500))

      let addWatchlistButtonObservable = addWatchlistBarButton.rx.tap.asObservable()

      let viewDisappeared = rx.viewWillDisappear
         .void()
         .asDriver(onErrorJustReturn: ())

      let cellSelected = tableView.rx.modelSelected(MutableBox<CurrencyPair>.self)
         .asObservable()

      let output = viewModel.transform(input:
         .init(addWatchlistButtonObservable: addWatchlistButtonObservable,
               watchlistDeleteObservable: deleteIndexPathSubject.asObservable(),
               visibleCellRows: mergedVisibleCells,
               viewDisappeared: viewDisappeared,
               cellSelected: cellSelected,
               fromIndexToIndexObservable: fromIndexToIndexSubject.asObservable()))

      let dataSource = RxTableViewSectionedReloadDataSource<WatchlistListData>(configureCell: { _, tv, indexPath, item -> UITableViewCell in
         if let spacer = tv.reorder.spacerCell(for: indexPath) {
            return spacer
         }

         let cell = tv.dequeueReusableCell(withIdentifier: WatchlistTableViewCell.identifier, for: indexPath)
         guard let priceCell = cell as? WatchlistTableViewCell else {
            return UITableViewCell()
         }
         _ = priceCell.bind(input: WatchlistCellViewModel.Input(currencyPair: item,
                                                                streamPrice: output.streamPrice,
                                                                historicalPriceAPI: output.historicalPriceAPI))
         priceCell.delegate = self

         ThemeProvider.current
            .drive(onNext: { theme in
               if indexPath.row % 2 == 0 {
                  theme.cellOne.apply(to: priceCell)
               } else {
                  theme.cellTwo.apply(to: priceCell)
               }
            })
            .disposed(by: self.disposeBag)

         return priceCell
      })

      self.dataSource = dataSource

      output.currencyPairs
         .drive(tableView.rx.items(dataSource: dataSource))
         .disposed(by: disposeBag)

      output.loadStateViewModel.output
         .isContentHidden
         .drive(tableView.rx.isHidden)
         .disposed(by: disposeBag)

      output.addWatchlistDriver
         .drive()
         .disposed(by: disposeBag)

      output.reloadTriggerDriver
         .drive(onNext: { [weak self] _ in
            self?.tableViewDataTrigger.on(.next(()))
         })
         .disposed(by: disposeBag)

      output.updateWatchlistDriver
         .drive(onNext: { [weak self] _ in
            self?.tableViewDataTrigger.on(.next(()))
         })
         .disposed(by: disposeBag)

      loadStateView.bind(state: output.loadStateViewModel)

      ThemeProvider.current
         .drive(onNext: { [weak self] theme in
            guard let `self` = self else {
               return
            }
            theme.tableView.apply(to: self.tableView)
            theme.view.apply(to: self.view)
         })
         .disposed(by: disposeBag)

      output.unsubscribeSocket
         .drive()
         .disposed(by: disposeBag)

      output.cellSelected
         .drive()
         .disposed(by: disposeBag)

      output.reloadTableViewOnErrorSignal
         .emit(onNext: { [weak self] _ in
            self?.tableView.reloadData()
         })
         .disposed(by: disposeBag)

      let isHidden = output.isLoading
         .map { !$0 }

      let loadingIndicatorInput = LoadingIndicatorViewModel.Input(isHidden: isHidden,
                                                                  state: output.loadingIndicatorState)
      _ = loadingIndicator.bind(input: loadingIndicatorInput)
   }
}

extension WatchlistViewController: SwipeTableViewCellDelegate {
   func tableView(_ tableView: UITableView,
                  editActionsForRowAt indexPath: IndexPath,
                  for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
      guard orientation == .right else { return nil }

      let deleteAction = SwipeAction(style: .destructive,
                                     title: nil) { [weak self] _, indexPath in
         self?.deleteIndexPathSubject.onNext(indexPath)
      }

      deleteAction.image = Image.deleteIcon.resource
      deleteAction.hidesWhenSelected = true

      return [deleteAction]
   }
}

extension WatchlistViewController: TableViewReorderDelegate {
   func tableView(_ tableView: UITableView,
                  reorderRowAt sourceIndexPath: IndexPath,
                  to destinationIndexPath: IndexPath) {}

   func tableViewDidFinishReordering(_ tableView: UITableView,
                                     from initialSourceIndexPath: IndexPath,
                                     to finalDestinationIndexPath: IndexPath) {
      guard initialSourceIndexPath != finalDestinationIndexPath else { return }
      fromIndexToIndexSubject.onNext((initialSourceIndexPath, finalDestinationIndexPath))
   }
}

extension WatchlistViewController: UIViewControllerPreviewingDelegate {
   private func getWatchlistDetailViewController(currencyPair: CurrencyPair) -> UIViewController? {
      let navigator = WatchlistDetailNavigator(state: .init(parent: viewModel.navigator))
      navigator.currencyPair = currencyPair
      let viewController = WatchlistDetailViewController(viewModel: .init(navigator: navigator))
      viewController.currencyPair = currencyPair

      let navigationController = BaseNavigationController(rootViewController: viewController)
      Style.NavigationBar.noHairline.apply(to: navigationController.navigationBar)
      navigationController.setNavigationBarHidden(true, animated: false)
      return navigationController
   }

   func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                          commit viewControllerToCommit: UIViewController) {
      guard let baseNavController = viewControllerToCommit as? BaseNavigationController,
         let viewController = baseNavController.viewControllers.first as? WatchlistDetailViewController else {
         return
      }

      viewModel.navigator.showWatchlistDetail(viewController.currencyPair)

      var metadata = viewController.currencyPair.analyticsMetadata
      metadata.updateValue("3D Touch", forKey: "Navigation Method")
      AnalyticsProvider.log(event: "Show Currency Pair Detail", metadata: metadata)
   }

   func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                          viewControllerForLocation location: CGPoint) -> UIViewController? {
      guard let indexPath = tableView.indexPathForRow(at: location),
         let cell = tableView.cellForRow(at: indexPath),
         let currencyPair = dataSource?[indexPath].value else { return nil }

      let viewController = getWatchlistDetailViewController(currencyPair: currencyPair)
      previewingContext.sourceRect = cell.frame
      return viewController
   }
}
