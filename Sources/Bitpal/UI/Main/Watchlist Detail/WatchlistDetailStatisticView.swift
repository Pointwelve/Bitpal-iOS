//
//  WatchlistDetailStatisticView.swift
//  App
//
//  Created by Kok Hong Choo on 16/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import RxCocoa
import RxSwift
import UIKit

final class WatchlistDetailStatisticView: UIView, BaseViewType, Bindable {
   private enum Metric {
      static let textLeadingTrailing: CGFloat = 16.0
      static let heightConstant: CGFloat = 44.0
   }

   private lazy var titleLabel: UILabel = {
      let label = UILabel()
      label.translatesAutoresizingMaskIntoConstraints = false

      return label
   }()

   private lazy var detailLabel: UILabel = {
      let label = UILabel()
      label.translatesAutoresizingMaskIntoConstraints = false
      label.text = "-"
      return label
   }()

   let currencyDetail = BehaviorRelay<CurrencyDetail?>(value: nil)

   let index = BehaviorRelay<Int?>(value: nil)

   var disposeBag = DisposeBag()

   let watchlistDetailData: WatchlistDetailData

   init(watchlistDetailData: WatchlistDetailData) {
      self.watchlistDetailData = watchlistDetailData
      super.init(frame: CGRect.zero)
      layout()
      bind()
   }

   required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
   }

   func layout() {
      [titleLabel, detailLabel].forEach(addSubview)

      NSLayoutConstraint.activate([
         titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor,
                                             constant: Metric.textLeadingTrailing),
         titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

         detailLabel.trailingAnchor.constraint(equalTo: trailingAnchor,
                                               constant: -Metric.textLeadingTrailing),
         detailLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

         heightAnchor.constraint(equalToConstant: Metric.heightConstant)
      ])
   }

   func bind() {
      currencyDetail.asDriver()
         .filterNil()
         .map { [weak self] detail -> String in
            self?.watchlistDetailData.getContent(detail) ?? "-"
         }
         .drive(detailLabel.rx.text)
         .disposed(by: disposeBag)

      Driver.combineLatest(ThemeProvider.current, index.asDriver().filterNil())
         .drive(onNext: { [weak self] theme, index in
            guard let `self` = self else { return }
            self.titleLabel.attributedText = theme.watchDetailStatisticTitle(self.watchlistDetailData.title)
            theme.watchDetailStatisticDetailLabel.apply(to: self.detailLabel)
            if index % 2 == 0 {
               self.backgroundColor = theme.watchDetailStatisticColorOne
            } else {
               self.backgroundColor = theme.watchDetailStatisticColorTwo
            }
         }).disposed(by: disposeBag)
   }
}
