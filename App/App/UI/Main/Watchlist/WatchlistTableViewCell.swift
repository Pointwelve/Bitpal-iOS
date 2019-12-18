//
//  PriceListTableViewCell.swift
//  App
//
//  Created by Hong on 26/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import LTMorphingLabel
import RxCocoa
import RxSwift
import UIKit

final class PriceListTableViewCell: UITableViewCell, ViewType {
   private enum Metric {
      static let priceCellTopBottomGap: CGFloat = 15.0
      static let profitLostWidthHeight: CGFloat = 10.0
      static let priceCellTextGap: CGFloat = 5.0
   }

   var viewModel: WatchlistCellViewModel!

   var disposeBag: DisposeBag!

   typealias ViewModel = WatchlistCellViewModel

   public static let identifier = String(describing: PriceListTableViewCell.self)

   private lazy var baseCurrencyLabel: UILabel = {
      let label = UILabel()
      label.translatesAutoresizingMaskIntoConstraints = false
      Style.Label.priceListWhiteText.apply(to: label)
      return label
   }()

   private lazy var quoteCurrencyLabel: UILabel = {
      let label = UILabel()
      label.translatesAutoresizingMaskIntoConstraints = false
      Style.Label.priceListGrayText.apply(to: label)
      return label
   }()

   private lazy var priceLabel: LTMorphingLabel = {
      let label = LTMorphingLabel()
      label.translatesAutoresizingMaskIntoConstraints = false
      Style.Label.priceListWhiteText.apply(to: label)
      return label
   }()

   private lazy var priceChangeView: UIView = {
      let view = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
      view.translatesAutoresizingMaskIntoConstraints = false
      Style.View.circle.apply(to: view)
      view.backgroundColor = UIColor.green
      return view
   }()

   override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
      super.init(style: style, reuseIdentifier: reuseIdentifier)
      disposeBag = DisposeBag()
      viewModel = WatchlistCellViewModel()
      layout()
   }

   required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
   }

   func layout() {
      selectionStyle = .none

      [baseCurrencyLabel, quoteCurrencyLabel, priceLabel, priceChangeView].forEach(contentView.addSubview)

      NSLayoutConstraint.activate([ // ProfitLossView
         priceChangeView.widthAnchor.constraint(equalToConstant: Metric.profitLostWidthHeight),
         priceChangeView.heightAnchor.constraint(equalTo: priceChangeView.widthAnchor),
         priceChangeView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: Metric.priceCellTopBottomGap),
         priceChangeView.centerYAnchor.constraint(equalTo: baseCurrencyLabel.centerYAnchor),

         // From Currency Label
         baseCurrencyLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Metric.priceCellTopBottomGap),
         baseCurrencyLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                                   constant: -Metric.priceCellTopBottomGap),
         baseCurrencyLabel.leftAnchor.constraint(equalTo: priceChangeView.rightAnchor,
                                                 constant: Metric.priceCellTopBottomGap),

         // To Currency Label
         quoteCurrencyLabel.topAnchor.constraint(equalTo: contentView.topAnchor,
                                                 constant: Metric.priceCellTopBottomGap),
         quoteCurrencyLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                                    constant: -Metric.priceCellTopBottomGap),
         quoteCurrencyLabel.leftAnchor.constraint(equalTo: baseCurrencyLabel.rightAnchor,
                                                  constant: Metric.priceCellTextGap),

         // Price Label
         priceLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Metric.priceCellTopBottomGap),
         priceLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Metric.priceCellTopBottomGap),
         priceLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -Metric.priceCellTopBottomGap)
      ])
   }

   func bind() {
      // no op
   }

   func bind(currencyPair: CurrencyPair, streamPrice: Driver<StreamPrice>) {
      let output = viewModel.transform(input: .init(currencyPair: currencyPair, streamPrice: streamPrice))

      baseCurrencyLabel.text = output.baseCurrencyText
      quoteCurrencyLabel.text = output.quoteCurrencyText
      output.priceText.drive(priceLabel.rx.text).disposed(by: disposeBag)
      output.priceChange.drive(onNext: { [weak self] color in
         self?.priceChangeView.backgroundColor = color
      }).disposed(by: disposeBag)
   }
}
