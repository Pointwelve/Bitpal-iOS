//
//  AlertsViewController.swift
//  App
//
//  Created by James Lai on 10/10/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import RxCocoa
import RxSwift
import SwipeCellKit
import UIKit

class AlertsViewController: UIViewController, DefaultViewControllerType, ScreenNameable {
   private enum Metric {
      static let rowHeight: CGFloat = 60.0
   }

   var screenNameAccessibilityId: AccessibilityIdentifier {
      return .alertsTitle
   }

   var viewModel: AlertsViewModel!
   var disposeBag = DisposeBag()

   fileprivate var deleteIndexPathSubject = PublishSubject<IndexPath>()

   private lazy var loadStateView: LoadStateView = {
      let view = LoadStateView()
      view.translatesAutoresizingMaskIntoConstraints = false
      view.isHidden = true
      return view
   }()

   private lazy var tableView: UITableView = {
      let tableView = UITableView()
      tableView.translatesAutoresizingMaskIntoConstraints = false
      tableView.rowHeight = Metric.rowHeight
      tableView.register(AlertsTableViewCell.self, forCellReuseIdentifier: AlertsTableViewCell.identifier)

      return tableView
   }()

   private var loadingIndicator: LoadingIndicator = {
      let view = LoadingIndicator()
      view.translatesAutoresizingMaskIntoConstraints = false
      view.isHidden = true

      return view
   }()

   func layout() {
      update(screenName: "alerts.title".localized())

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
   }

   func bind() {
      let viewWillAppear = rx.viewWillAppear
         .void()
         .asDriver()

      let willEnterForeground = NotificationCenter.default.rx
         .notification(UIApplication.willEnterForegroundNotification)
         .void()
         .asDriver(onErrorJustReturn: ())
         .startWith(())

      let isRegisteredForRemoteNotifications = Driver.combineLatest(viewWillAppear, willEnterForeground)
         .flatMapLatest { _ in
            UIApplication.shared.isEnabledForRemoteNotifications()
         }

      let noNotificationButtonAction = {
         if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
         }
      }

      let output = viewModel
         .transform(input: .init(isRegisteredForRemoteNotifications: isRegisteredForRemoteNotifications,
                                 noNotificationButtonAction: noNotificationButtonAction,
                                 viewWillAppear: viewWillAppear,
                                 deleteAlert: deleteIndexPathSubject.asObservable()))

      output.alerts
         .drive(tableView.rx.items(cellIdentifier: AlertsTableViewCell.identifier)) { index, model, cell in
            guard let alertsCell = cell as? AlertsTableViewCell else {
               return
            }

            let didTapAlertSwitch = alertsCell.alertSwitch.rx.isOn.asDriver()
            _ = alertsCell.bind(input: AlertsTableViewModel.Input(alert: model,
                                                                  didTapAlertSwicth: didTapAlertSwitch,
                                                                  updateAlertApi: output.updateAlertApi))
            alertsCell.delegate = self

            ThemeProvider.current
               .drive(onNext: { theme in
                  if index % 2 == 0 {
                     theme.cellOne.apply(to: alertsCell)
                  } else {
                     theme.cellTwo.apply(to: alertsCell)
                  }
               })
               .disposed(by: self.disposeBag)
         }
         .disposed(by: disposeBag)

      output.viewWillAppear
         .drive()
         .disposed(by: disposeBag)

      output.deleteAlert
         .drive()
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

extension AlertsViewController: SwipeTableViewCellDelegate {
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
