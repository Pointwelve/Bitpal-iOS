//
//  WatchlistSelectExchangeViewController.swift
//  App
//
//  Created by Li Hao on 19/1/18.
//  Copyright © 2018 Pointwelve. All rights reserved.
//

import Domain
import RxCocoa
import RxSwift
import UIKit

class WatchlistSelectExchangeViewController: UIViewController, DefaultViewControllerType, ScreenNameable {
   fileprivate enum Metric {
      static let leftAnchorMargin: CGFloat = 16.0
      static let rightAnchorMargin: CGFloat = 16.0
      static let titleHeaderHeight: CGFloat = 37.0
      static let clearButtonWidth: CGFloat = 31.5
      static let clearButtonHeight: CGFloat = 17.0
      static let clearButtonRightMargin: CGFloat = 14.5
      static let searchTitleTextFieldHeight: CGFloat = 20.0
      static let searchTextFieldLeading: CGFloat = 14.5
      static let headerBaseFullnameLeftAnchorMargin: CGFloat = 6.0
   }

   var disposeBag = DisposeBag()
   var viewModel: WatchlistSelectExchangeViewModel!

   private lazy var loadStateView: LoadStateView = {
      let view = LoadStateView()
      view.translatesAutoresizingMaskIntoConstraints = false
      view.isHidden = true
      return view
   }()

   private lazy var tableView: UITableView = {
      let tableView = UITableView()
      tableView.translatesAutoresizingMaskIntoConstraints = false
      tableView.estimatedRowHeight = 40.0
      tableView.rowHeight = UITableView.automaticDimension
      tableView.registerCell(of: WatchlistSelectExchangeTableViewCell.self)
      tableView.keyboardDismissMode = .onDrag

      return tableView
   }()

   private var loadingIndicator: LoadingIndicator = {
      let view = LoadingIndicator()
      view.translatesAutoresizingMaskIntoConstraints = false
      view.isHidden = true

      return view
   }()

   var screenNameAccessibilityId: AccessibilityIdentifier {
      return .selectExchangeTitle
   }

   func layout() {
      update(screenName: "Select an exchange")

      if #available(iOS 11.0, *) {
         // iOS 11 behave differently on autolayout constraint
         navigationItem.largeTitleDisplayMode = .never
      }

      [loadStateView, tableView].forEach(view.addSubview)

      NSLayoutConstraint.activate([
         loadStateView.topAnchor.constraint(equalTo: view.topAnchor),
         loadStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
         loadStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
         loadStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

         tableView.topAnchor.constraint(equalTo: view.topAnchor),
         tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
         tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
         tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
      ])
   }

   func bind() {
      let tableViewItemSelected = tableView.rx.modelSelected(Exchange.self).asDriver()

      let output = viewModel.transform(input: .init(tableViewItemSelected: tableViewItemSelected))

      output.exchanges
         .drive(tableView.rx.items(cellIdentifier: WatchlistSelectExchangeTableViewCell.identifier)) { _, model, cell in
            guard let exchangeCell = cell as? WatchlistSelectExchangeTableViewCell else {
               return
            }
            exchangeCell.bind(exchange: model)
         }
         .disposed(by: disposeBag)

      output.loadStateViewModel.output
         .isContentHidden
         .drive(tableView.rx.isHidden)
         .disposed(by: disposeBag)

      loadStateView.bind(state: output.loadStateViewModel)

      let isHidden = output.isLoading
         .map { !$0 }

      let loadingIndicatorInput = LoadingIndicatorViewModel.Input(isHidden: isHidden,
                                                                  state: output.loadingIndicatorState)
      _ = loadingIndicator.bind(input: loadingIndicatorInput)

      ThemeProvider.current
         .drive(onNext: { [weak self] theme in
            guard let `self` = self else {
               return
            }
            theme.tableView.apply(to: self.tableView)
            theme.view.apply(to: self.view)
         })
         .disposed(by: disposeBag)
   }
}
