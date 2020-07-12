//
//  TodayViewController.swift
//  Widget
//
//  Created by Li Hao Lai on 29/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import NotificationCenter
import RxCocoa
import RxGesture
import RxSwift
import UIKit

enum Style {
   enum Label {
      public static let exchangeLabel: UIViewStyle<UILabel> = UIViewStyle {
         $0.font = UIFont.systemFont(ofSize: 11.0)
      }

      public static let baseLabel: UIViewStyle<UILabel> = UIViewStyle {
         $0.font = UIFont.systemFont(ofSize: 18.0)
      }

      public static let priceLabel: UIViewStyle<UILabel> = UIViewStyle {
         $0.textAlignment = .right
         $0.font = UIFont.systemFont(ofSize: 18.0)
      }

      public static let percentageLabel: UIViewStyle<UILabel> = UIViewStyle {
         $0.textColor = UIColor.white
         $0.font = UIFont.systemFont(ofSize: 13.0)
      }

      public static let loadStateTitleLabel: UIViewStyle<UILabel> = UIViewStyle {
         $0.textAlignment = .center
         $0.font = UIFont.systemFont(ofSize: 17.0)
      }

      public static let loadStateMessageLabel: UIViewStyle<UILabel> = UIViewStyle {
         $0.textAlignment = .center
         $0.font = UIFont.systemFont(ofSize: 12.0)
      }
   }

   enum View {
      static func radius(with radius: CGFloat) -> UIViewStyle<UIView> {
         return UIViewStyle<UIView> {
            $0.layer.cornerRadius = radius
         }
      }
   }
}

@objc(TodayViewController)
class TodayViewController: UIViewController, NCWidgetProviding {
   override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
      super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
   }

   required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
   }

   private enum Metric {
      static let compactHeight: CGFloat = 110.0
      static let rowHeight: CGFloat = 55.0
      static let viewLeading: CGFloat = 8.0
      static let viewTrailing: CGFloat = -8.0
   }

   let disposeBag = DisposeBag()

   var viewModel: TodayViewModel!

   private lazy var tableView: UITableView = {
      let tableView = UITableView()
      tableView.translatesAutoresizingMaskIntoConstraints = false
      tableView.rowHeight = Metric.rowHeight
      tableView.allowsSelection = false
      tableView.register(TodayTableViewCell.self, forCellReuseIdentifier: TodayTableViewCell.identifier)
      return tableView
   }()

   private lazy var loadStateView: WidgetLoadStateView = {
      let loadStateView = WidgetLoadStateView()
      loadStateView.translatesAutoresizingMaskIntoConstraints = false
      return loadStateView
   }()

   override func viewDidLoad() {
      super.viewDidLoad()

      viewModel = TodayViewModel(preference: WidgetPreference())
      layout()
      bind()
   }

   func widgetPerformUpdate(completionHandler: @escaping (NCUpdateResult) -> Void) {
      // Perform any setup necessary in order to update the view.

      // If an error is encountered, use NCUpdateResult.Failed
      // If there's no update required, use NCUpdateResult.NoData
      // If there's an update, use NCUpdateResult.NewData

      completionHandler(NCUpdateResult.newData)
   }

   func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
      preferredContentSize = CGSize(width: 0.0,
                                    height: activeDisplayMode == .expanded
                                       ? Metric.rowHeight * CGFloat(tableView.numberOfRows(inSection: 0))
                                       : Metric.compactHeight)
   }

   func layout() {
      [tableView, loadStateView].forEach(view.addSubview)

      NSLayoutConstraint.activate([
         tableView.topAnchor.constraint(equalTo: view.topAnchor),
         tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Metric.viewLeading),
         tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: Metric.viewTrailing),
         tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

         loadStateView.topAnchor.constraint(equalTo: view.topAnchor),
         loadStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Metric.viewLeading),
         loadStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: Metric.viewTrailing),
         loadStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
      ])
   }

   func bind() {
      let loadStateViewTap = loadStateView.rx.tapGesture()
         .when(.recognized)
         .asDriver(onErrorJustReturn: UITapGestureRecognizer())
         .void()

      let output = viewModel.transform(input: .init(loadStateViewTap: loadStateViewTap))

      output.watclistRequestDriver
         .drive()
         .disposed(by: disposeBag)

      output.watchlist
         .drive(onNext: {
            self.extensionContext?.widgetLargestAvailableDisplayMode = $0.count > 2 ? .expanded : .compact
         })
         .disposed(by: disposeBag)

      output.watchlist
         .drive(tableView.rx.items(cellIdentifier: TodayTableViewCell.identifier)) { _, model, cell in
            guard let todayCell = cell as? TodayTableViewCell else {
               return
            }

            todayCell.currencyPair.accept(model)
            todayCell.getCurrencyDetailsAction.accept(output.getCurrencyDetailsAction)
         }
         .disposed(by: disposeBag)

      output.loadState
         .drive(onNext: {
            self.tableView.isHidden = $0 != .ready
            self.loadStateView.bind(viewModel: WidgetLoadStateViewModel(), loadState: $0)
         })
         .disposed(by: disposeBag)

      output.loadStateViewDidTap
         .drive(onNext: { _ in
            guard let url = URL(string: "bitpal://") else {
               return
            }

            self.extensionContext?.open(url, completionHandler: nil)
         })
         .disposed(by: disposeBag)
   }
}
