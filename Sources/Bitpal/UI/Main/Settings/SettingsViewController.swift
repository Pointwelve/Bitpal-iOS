//
//  SettingsViewController.swift
//  App
//
//  Created by Kok Hong Choo on 20/7/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import UIKit

final class SettingsViewController: UIViewController,
   ScreenNameable, DefaultViewControllerType {
   private enum Metric {
      static let versionLabelBottom: CGFloat = 18.0
      static let cellHeight: CGFloat = 56.0
   }

   var screenNameAccessibilityId: AccessibilityIdentifier {
      return .settingsNavigationTitle
   }

   typealias ViewModel = SettingsViewModel

   var disposeBag = DisposeBag()
   var viewModel: SettingsViewModel!

   private lazy var versionLabel: UILabel = {
      let label = UILabel()
      label.translatesAutoresizingMaskIntoConstraints = false
      label.setAccessibility(id: .settingsVersionLabel)
      return label
   }()

   private lazy var tableView: UITableView = {
      let tableView = UITableView()
      tableView.translatesAutoresizingMaskIntoConstraints = false
      tableView.rowHeight = Metric.cellHeight
      tableView.register(SettingsTableViewCell.self, forCellReuseIdentifier: SettingsTableViewCell.identifier)
      tableView.setAccessibility(id: .settingsTable)
      return tableView
   }()

   func layout() {
      [tableView, versionLabel].forEach(view.addSubview)
      NSLayoutConstraint.activate([ // Table View
         tableView.topAnchor.constraint(equalTo: view.topAnchor),
         tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
         tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
         tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

         // Version Label
         versionLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Metric.versionLabelBottom),
         versionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
      ])
   }

   func bind() {
      let settingSelectedObservable = tableView.rx.modelSelected(SettingListData.self).asObservable()

      let output = viewModel.transform(input: .init(settingSelectedObservable: settingSelectedObservable))
      update(screenName: output.title)
      versionLabel.text = output.version

      output.settingsData
         .drive(tableView.rx.items(cellIdentifier: SettingsTableViewCell.identifier)) { index, model, cell in
            guard let settingCell = cell as? SettingsTableViewCell else {
               return
            }

            ThemeProvider.current
               .drive(onNext: { theme in
                  if index % 2 == 0 {
                     theme.cellOne.apply(to: settingCell)
                  } else {
                     theme.cellTwo.apply(to: settingCell)
                  }
               })
               .disposed(by: self.disposeBag)

            settingCell.settingsData.accept(model)
            settingCell.setAccessibility(id: model.accessibilityId)
         }
         .disposed(by: disposeBag)

      output.settingSelectedDriver
         .drive()
         .disposed(by: disposeBag)

      ThemeProvider.current
         .drive(onNext: { theme in
            theme.tableView.apply(to: self.tableView)
            theme.settingsVersionLabel.apply(to: self.versionLabel)
            theme.view.apply(to: self.view)
         })
         .disposed(by: disposeBag)
   }
}
