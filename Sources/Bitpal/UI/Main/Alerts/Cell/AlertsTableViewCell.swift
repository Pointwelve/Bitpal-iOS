//
//  AlertsTableViewCell.swift
//  App
//
//  Created by James Lai on 10/10/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import RxCocoa
import RxSwift
import SwipeCellKit
import UIKit

class AlertsTableViewCell: SwipeTableViewCell, IOBindableViewType {
   private enum Metrics {
      static let fromSymbolLeading: CGFloat = 15.0
      static let fromSymbolTop: CGFloat = 11.0
      static let toSymbolLeading: CGFloat = 3.0
      static let switchTrailing: CGFloat = -10.0
      static let switchWidth: CGFloat = 50
      static let switchHeight: CGFloat = 30
      static let quoteLabelBottom: CGFloat = -1.0
   }

   typealias ViewModel = AlertsTableViewModel

   var viewModel: AlertsTableViewModel!
   var disposeBag = DisposeBag()

   public static let identifier = String(describing: AlertsTableViewCell.self)

   private var fromSymbolLabel: UILabel = {
      let label = UILabel()
      label.translatesAutoresizingMaskIntoConstraints = false
      return label
   }()

   private var toSymbolLabel: UILabel = {
      let label = UILabel()
      label.translatesAutoresizingMaskIntoConstraints = false
      Style.Label.quoteSymbolLabel.apply(to: label)
      return label
   }()

   private var exchangeLabel: UILabel = {
      let label = UILabel()
      label.translatesAutoresizingMaskIntoConstraints = false
      return label
   }()

   private var alertPriceLabel: UILabel = {
      let label = UILabel()
      label.translatesAutoresizingMaskIntoConstraints = false
      Style.Label.alertPriceLabel.apply(to: label)
      return label
   }()

   public var alertSwitch: UISwitch = {
      let switchView = UISwitch()
      switchView.tintColor = Color.tealish
      switchView.onTintColor = Color.tealish
      switchView.translatesAutoresizingMaskIntoConstraints = false
      return switchView
   }()

   override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
      super.init(style: style, reuseIdentifier: reuseIdentifier)
      viewModel = AlertsTableViewModel()
      layout()
   }

   required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
   }

   func layout() {
      [fromSymbolLabel, toSymbolLabel, exchangeLabel, alertPriceLabel, alertSwitch].forEach(contentView.addSubview)

      selectionStyle = .none

      NSLayoutConstraint.activate([
         fromSymbolLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                  constant: Metrics.fromSymbolLeading),
         fromSymbolLabel.topAnchor.constraint(equalTo: contentView.topAnchor,
                                              constant: Metrics.fromSymbolTop),

         toSymbolLabel.leadingAnchor.constraint(equalTo: fromSymbolLabel.trailingAnchor,
                                                constant: Metrics.toSymbolLeading),
         toSymbolLabel.bottomAnchor.constraint(equalTo: fromSymbolLabel.bottomAnchor,
                                               constant: Metrics.quoteLabelBottom),

         exchangeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                constant: Metrics.fromSymbolLeading),
         exchangeLabel.topAnchor.constraint(equalTo: fromSymbolLabel.bottomAnchor),

         alertPriceLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
         alertPriceLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

         alertSwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                               constant: Metrics.switchTrailing),
         alertSwitch.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
         alertSwitch.widthAnchor.constraint(equalToConstant: Metrics.switchWidth),
         alertSwitch.heightAnchor.constraint(equalToConstant: Metrics.switchHeight)
      ])
   }

   func bind(input: AlertsTableViewModel.Input) -> AlertsTableViewModel.Output {
      let viewModel = AlertsTableViewModel()
      let output = viewModel.transform(input: input)

      output.alert
         .drive(onNext: { [weak self] alert in
            self?.fromSymbolLabel.text = alert.base
            self?.toSymbolLabel.text = alert.quote
            self?.exchangeLabel.text = alert.exchange
            self?.alertPriceLabel.text = "\(alert.comparison.symbol) \(alert.quote) \(alert.reference)"
            self?.alertSwitch.isOn = alert.isEnabled
         })
         .disposed(by: disposeBag)

      output.didTapAlertSwitch
         .drive(onNext: { [weak self] value in
            self?.alertSwitch.isEnabled = value
         })
         .disposed(by: disposeBag)

      ThemeProvider.current
         .drive(onNext: { [weak self] theme in
            guard let `self` = self else { return }

            theme.baseSymbolLabel.apply(to: self.fromSymbolLabel)
            theme.alertExchangeLabel.apply(to: self.exchangeLabel)
         })
         .disposed(by: disposeBag)

      return output
   }

   override func prepareForReuse() {
      super.prepareForReuse()
      disposeBag = DisposeBag()
      hideSwipe(animated: true)
   }
}
