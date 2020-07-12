//
//  WatchlistSelectExchangeTableViewCell.swift
//  App
//
//  Created by Li Hao Lai on 20/1/18.
//  Copyright © 2018 Pointwelve. All rights reserved.
//

import Domain
import RxCocoa
import RxSwift
import UIKit

final class WatchlistSelectExchangeTableViewCell: UITableViewCell, BaseViewType {
   private enum Metric {
      static let leftAnchorConstant: CGFloat = 16.0
      static let fullnameLeftAnchorConstant: CGFloat = 6.0
   }

   typealias ViewModel = WatchlistSelectExchangeTabeCellViewModel

   var viewModel: ViewModel!
   var disposeBag = DisposeBag()

   public static let identifier = String(describing: WatchlistSelectExchangeTableViewCell.self)

   private lazy var exchangeLabel: UILabel = {
      let label = UILabel()
      label.translatesAutoresizingMaskIntoConstraints = false

      return label
   }()

   override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
      super.init(style: style, reuseIdentifier: reuseIdentifier)
      disposeBag = DisposeBag()
      viewModel = WatchlistSelectExchangeTabeCellViewModel()
      layout()
      bind()
   }

   required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
   }

   func layout() {
      [exchangeLabel].forEach(contentView.addSubview)

      NSLayoutConstraint.activate([
         exchangeLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: Metric.leftAnchorConstant),
         exchangeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
      ])
   }

   func bind() {
      ThemeProvider.current
         .drive(onNext: { [weak self] theme in
            guard let `self` = self else { return }
            theme.view.apply(to: self.contentView)
            theme.selectExchangeLabel.apply(to: self.exchangeLabel)
         })
         .disposed(by: disposeBag)
   }

   func bind(exchange: Exchange) {
      exchangeLabel.text = exchange.localizedFullname
   }
}
