//
//  WatchlistAddColnTableViewCell.swift
//  App
//
//  Created by Li Hao Lai on 25/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import RxCocoa
import RxSwift
import UIKit

final class WatchlistAddCoinTableViewCell: UITableViewCell, BaseViewType {
   private enum Metric {
      static let leftAnchorConstant: CGFloat = 16.0
      static let fullnameLeftAnchorConstant: CGFloat = 6.0
   }

   typealias ViewModel = WatchlistAddCoinCellViewModel

   var viewModel: ViewModel!
   var disposeBag = DisposeBag()

   public static let identifier = String(describing: WatchlistAddCoinTableViewCell.self)

   private lazy var baseCurrencyLabel: UILabel = {
      let baseCurrencyLabel = UILabel()
      baseCurrencyLabel.translatesAutoresizingMaskIntoConstraints = false

      return baseCurrencyLabel
   }()

   private lazy var quoteCurrencyLabel: UILabel = {
      let quoteCurrencyLabel = UILabel()
      quoteCurrencyLabel.translatesAutoresizingMaskIntoConstraints = false
      Style.Label.priceListGrayText.apply(to: quoteCurrencyLabel)

      return quoteCurrencyLabel
   }()

   override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
      super.init(style: style, reuseIdentifier: reuseIdentifier)
      disposeBag = DisposeBag()
      viewModel = WatchlistAddCoinCellViewModel()
      layout()
      bind()
   }

   required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
   }

   func layout() {
      [baseCurrencyLabel, quoteCurrencyLabel].forEach(contentView.addSubview)

      NSLayoutConstraint.activate([
         baseCurrencyLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: Metric.leftAnchorConstant),
         baseCurrencyLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
         quoteCurrencyLabel.leftAnchor.constraint(equalTo: baseCurrencyLabel.rightAnchor,
                                                  constant: Metric.fullnameLeftAnchorConstant),
         quoteCurrencyLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
      ])
   }

   func bind() {
      ThemeProvider.current
         .drive(onNext: { [weak self] theme in
            guard let `self` = self else { return }
            theme.view.apply(to: self.contentView)
            theme.priceList.apply(to: self.baseCurrencyLabel)
         })
         .disposed(by: disposeBag)
   }

   func bind(currencyPairGroup: CurrencyPairGroup) {
      let output = viewModel.transform(input: .init(currencyPairGroup: currencyPairGroup))

      baseCurrencyLabel.text = output.baseCurrencyText
      quoteCurrencyLabel.text = output.quoteCurrencyText
   }
}
