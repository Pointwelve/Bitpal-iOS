//
//  WatchlistTableViewCell.swift
//  App
//
//  Created by Hong on 26/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Charts
import Domain
import RxSwift
import SwipeCellKit
import UIKit

final class WatchlistTableViewCell: SwipeTableViewCell, IOBindableViewType {
   private enum Metric {
      static let priceLabelTrailing: CGFloat = 9.0
      static let baseCurrencyLeading: CGFloat = 20.0
      static let baseCurrencyTop: CGFloat = 16.0
      static let exchangePercentageTop: CGFloat = 0.0
      static let currencyLabelGap: CGFloat = 3.0
      static let exchangeLabelGap: CGFloat = 5.0
      static let percentageLabelViewBottom: CGFloat = 16.0
      static let percentageViewWidth: CGFloat = 47.0
      static let percentageViewHeight: CGFloat = 14.0
      static let percentageCornerRadius: CGFloat = 3.0
      static let graphAspectRatio: CGFloat = 38.0 / 75.0
      static let graphWidthRatio: CGFloat = 75.0 / 375.0
      static let nextArrowTrailing: CGFloat = 12.0
      static let quoteLabelBottom: CGFloat = -1.0

      enum ReferenceSize {
         static let graphAspectRatio: CGFloat = 75.0 / 38.0
         static let graphWidthRatio: CGFloat = 80 / 375.0
      }
   }

   var disposeBag = DisposeBag()

   public static let identifier = String(describing: WatchlistTableViewCell.self)

   // MARK: - UI Views

   private lazy var baseCurrencyLabel: UILabel = {
      let label = UILabel()
      label.translatesAutoresizingMaskIntoConstraints = false
      label.setAccessibility(id: .watchListBaseLabel)
      return label
   }()

   private lazy var quoteCurrencyLabel: UILabel = {
      let label = UILabel()
      label.translatesAutoresizingMaskIntoConstraints = false
      label.setAccessibility(id: .watchListQuoteLabel)
      Style.Label.quoteSymbolLabel.apply(to: label)
      return label
   }()

   private lazy var priceLabel: UILabel = {
      let label = UILabel()
      label.translatesAutoresizingMaskIntoConstraints = false
      label.setAccessibility(id: .watchListPriceLabel)
      label.text = "-"
      return label
   }()

   private lazy var exchangeLabel: UILabel = {
      let label = UILabel()
      label.translatesAutoresizingMaskIntoConstraints = false
      label.setAccessibility(id: .watchListExchangeLabel)

      return label
   }()

   private lazy var percentageLabel: UILabel = {
      let label = UILabel()
      label.translatesAutoresizingMaskIntoConstraints = false
      label.setAccessibility(id: .watchListPercentageLabel)
      return label
   }()

   private lazy var percentageLabelView: UIView = {
      let view = UIView()
      view.translatesAutoresizingMaskIntoConstraints = false
      view.setAccessibility(id: .watchListPercentageView)
      Style.View.radius(with: Metric.percentageCornerRadius).apply(to: view)
      return view
   }()

   private lazy var lineChartView: LineChartView = {
      let lineChartView = LineChartView()
      lineChartView.setAccessibility(id: .watchListGraphView)
      lineChartView.translatesAutoresizingMaskIntoConstraints = false
      lineChartView.xAxis.enabled = false
      lineChartView.legend.enabled = false
      lineChartView.rightAxis.enabled = false
      lineChartView.chartDescription?.enabled = false
      lineChartView.dragEnabled = false
      lineChartView.drawGridBackgroundEnabled = false
      lineChartView.pinchZoomEnabled = false
      lineChartView.scaleXEnabled = false
      lineChartView.scaleYEnabled = false
      lineChartView.isUserInteractionEnabled = false
      lineChartView.noDataTextColor = UIColor.white
      lineChartView.noDataText = "watchlist.graphLoading".localized()
      lineChartView.noDataFont = Font.light9
      lineChartView.noDataTextColor = Color.warmGrey
      let left = lineChartView.leftAxis
      left.drawLabelsEnabled = false
      left.drawAxisLineEnabled = false
      left.drawGridLinesEnabled = false
      left.drawZeroLineEnabled = true
      left.zeroLineDashLengths = [0.0, 4.5]
      left.zeroLineWidth = 1.0

      return lineChartView
   }()

   private lazy var nextArrowImageView: UIImageView = {
      let imageView = UIImageView()
      imageView.translatesAutoresizingMaskIntoConstraints = false

      return imageView
   }()

   // MARK: - UI Constraints

   override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
      super.init(style: style, reuseIdentifier: reuseIdentifier)
      setAccessibility(id: .watchListCell)
      setup()
   }

   required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
   }

   override func prepareForReuse() {
      super.prepareForReuse()
      disposeBag = DisposeBag()
      percentageLabelView.backgroundColor = Color.warmGrey
      percentageLabel.text = "-"
      lineChartView.clear()
      hideSwipe(animated: true)
   }

   func layout() {
      selectionStyle = .none
      [
         baseCurrencyLabel, quoteCurrencyLabel, exchangeLabel,
         percentageLabelView, priceLabel, lineChartView, nextArrowImageView
      ]
      .forEach(contentView.addSubview)

      [percentageLabel].forEach(percentageLabelView.addSubview)

      NSLayoutConstraint.activate([ // Price Label
         priceLabel.trailingAnchor.constraint(equalTo: nextArrowImageView.leadingAnchor,
                                              constant: -Metric.priceLabelTrailing),
         priceLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

         // Base Currency
         baseCurrencyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                    constant: Metric.baseCurrencyLeading),
         baseCurrencyLabel.topAnchor.constraint(equalTo: contentView.topAnchor,
                                                constant: Metric.baseCurrencyTop),

         // Quote Currency
         quoteCurrencyLabel.bottomAnchor.constraint(equalTo: baseCurrencyLabel.bottomAnchor,
                                                    constant: Metric.quoteLabelBottom),
         quoteCurrencyLabel.leadingAnchor.constraint(equalTo: baseCurrencyLabel.trailingAnchor,
                                                     constant: Metric.currencyLabelGap),

         // Exchange
         exchangeLabel.topAnchor.constraint(equalTo: baseCurrencyLabel.bottomAnchor,
                                            constant: Metric.exchangePercentageTop),
         exchangeLabel.leadingAnchor.constraint(equalTo: baseCurrencyLabel.leadingAnchor),

         // Percentage
         percentageLabelView.widthAnchor.constraint(equalToConstant: Metric.percentageViewWidth),
         percentageLabelView.heightAnchor.constraint(equalToConstant: Metric.percentageViewHeight),
         percentageLabelView.leadingAnchor.constraint(equalTo: exchangeLabel.trailingAnchor,
                                                      constant: Metric.exchangeLabelGap),
         percentageLabelView.centerYAnchor.constraint(equalTo: exchangeLabel.centerYAnchor),

         percentageLabel.centerXAnchor.constraint(equalTo: percentageLabelView.centerXAnchor),
         percentageLabel.centerYAnchor.constraint(equalTo: percentageLabelView.centerYAnchor),

         // Graph
         lineChartView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
         lineChartView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
         lineChartView.widthAnchor.constraint(equalTo: contentView.widthAnchor,
                                              multiplier: Metric.graphWidthRatio),
         lineChartView.heightAnchor.constraint(equalTo: lineChartView.widthAnchor,
                                               multiplier: Metric.graphAspectRatio),

         // Next Arrow Image View
         nextArrowImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                      constant: -Metric.nextArrowTrailing),
         nextArrowImageView.centerYAnchor.constraint(equalTo: priceLabel.centerYAnchor)
      ])
   }

   func bind(input: WatchlistCellViewModel.Input) -> WatchlistCellViewModel.Output {
      let viewModel = WatchlistCellViewModel()
      let output = viewModel.transform(input: input)

      baseCurrencyLabel.text = output.baseCurrencyText
      quoteCurrencyLabel.text = output.quoteCurrencyText
      exchangeLabel.text = output.exchange.localizedFullname
      output.priceText.drive(priceLabel.rx.text).disposed(by: disposeBag)

      output.priceChangePctText.drive(percentageLabel.rx.text).disposed(by: disposeBag)
      output.priceChangePctPriceChange.drive(onNext: { [weak self] priceChange in
         self?.percentageLabelView.backgroundColor = priceChange.color
      }).disposed(by: disposeBag)

      output.savePrice.drive().disposed(by: disposeBag)

      output.updateCryptoCurrency
         .drive()
         .disposed(by: disposeBag)

      output.chartData.drive(onNext: { [weak self] dataSets in
         self?.lineChartView.data = dataSets
      }).disposed(by: disposeBag)

      ThemeProvider.current.drive(onNext: { [weak self] theme in
         guard let `self` = self else {
            return
         }
         theme.priceListExchangeLabel.apply(to: self.exchangeLabel)
         theme.pricePercentageLabel.apply(to: self.percentageLabel)
         theme.priceListPriceLabel.apply(to: self.priceLabel)
         theme.baseSymbolLabel.apply(to: self.baseCurrencyLabel)
         theme.priceListNextArrowImageView(image: Image.nextIcon.resource).apply(to: self.nextArrowImageView)
         self.lineChartView.leftAxis.zeroLineColor = theme.priceListGraphZeroLineColor
      }).disposed(by: disposeBag)

      return output
   }
}
