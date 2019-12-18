//
//  WatchlistDetailViewController.swift
//  App
//
//  Created by Kok Hong Choo on 13/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Charts
import Crashlytics
import Domain
import RxCocoa
import RxGesture
import RxSwift
import SwipeCellKit
import UIKit

// swiftlint:disable type_body_length file_length
final class WatchlistDetailViewController: UIViewController, DefaultViewControllerType, ScreenNameable {
   fileprivate enum Metric {
      static let navigationBarHeight: CGFloat = 44.0
      static let graphContainerHeightRatio: CGFloat = 224.5 / 372.0
      static let graphHeightRatio: CGFloat = 151.0 / 372.0
      static let priceLabelTop: CGFloat = 9.0
      static let priceLabelLeading: CGFloat = 16.0
      static let priceLabelHeight: CGFloat = 50.0
      static let graphContainerTop: CGFloat = 15.0
      static let stackviewTop: CGFloat = 40.0
      static let chartPeriodHeight: CGFloat = 30.0
      static let pricePercentageContainerWidth: CGFloat = 68.0
      static let pricePercentageContainerHeight: CGFloat = 20.0
      static let percentageCornerRadius: CGFloat = 3.0
   }

   fileprivate enum PlaceHolder {
      static let priceDayAndPctText = "        _        "
      static let priceText = "_ _"
   }

   var disposeBag = DisposeBag()
   var viewModel: WatchlistDetailViewModel!

   var screenNameAccessibilityId: AccessibilityIdentifier {
      return .watchlistDetailTitle
   }

   private var statisticViews: [WatchlistDetailStatisticView] = []

   private lazy var watchlistBarButtonItem: UIBarButtonItem = {
      let button = UIBarButtonItem(image: Image.closeIcon.resource,
                                   style: .plain,
                                   target: nil,
                                   action: nil)

      return button
   }()

   private lazy var chartTypeBarButtonItem: UIBarButtonItem = {
      let button = UIBarButtonItem(image: Image.candleStickIcon.resource,
                                   style: .plain,
                                   target: nil,
                                   action: nil)

      return button
   }()

   private lazy var priceAlertBarButtonItem: UIBarButtonItem = {
      let button = UIBarButtonItem(image: Image.priceAlertIcon.resource,
                                   style: .plain,
                                   target: nil,
                                   action: nil)
      button.isEnabled = false

      return button
   }()

   private lazy var priceLabel: UILabel = {
      let label = UILabel()
      label.translatesAutoresizingMaskIntoConstraints = false
      label.setAccessibility(id: .watchlistDetailPriceLabel)
      label.numberOfLines = 2
      label.text = PlaceHolder.priceText
      label.textAlignment = .center
      label.adjustsFontSizeToFitWidth = true

      return label
   }()

   private lazy var percentageStackView: UIStackView = {
      let stackView = UIStackView()
      stackView.translatesAutoresizingMaskIntoConstraints = false
      Style.StackView.watchlistDetailPriceStackView.apply(to: stackView)
      return stackView
   }()

   private lazy var pricePercentageLabel: UILabel = {
      let label = UILabel()
      Style.Label.priceDetailBasePctLabel.apply(to: label)
      label.translatesAutoresizingMaskIntoConstraints = false
      label.setAccessibility(id: .watchlistDetailPricePctLabel)
      label.text = PlaceHolder.priceDayAndPctText
      return label
   }()

   private lazy var pricePercentageContainerView: UIView = {
      let view = UIView()
      view.translatesAutoresizingMaskIntoConstraints = false
      view.backgroundColor = Color.warmGrey
      Style.View.radius(with: Metric.percentageCornerRadius).apply(to: view)
      return view
   }()

   private lazy var priceDayLabel: UILabel = {
      let label = UILabel()
      label.translatesAutoresizingMaskIntoConstraints = false
      label.setAccessibility(id: .watchlistDetailPriceDayLabel)
      label.text = PlaceHolder.priceDayAndPctText
      return label
   }()

   private lazy var graphContainerView: UIView = {
      let view = UIView()
      view.translatesAutoresizingMaskIntoConstraints = false
      return view
   }()

   private lazy var graphBackgroudnImageView: UIImageView = {
      let imageView = UIImageView()
      imageView.translatesAutoresizingMaskIntoConstraints = false
      imageView.contentMode = .scaleAspectFill
      return imageView
   }()

   private lazy var candleGraphView: CandleStickChartView = {
      let view = CandleStickChartView()
      view.xAxis.enabled = false
      view.rightAxis.enabled = false
      view.chartDescription?.enabled = false
      view.drawGridBackgroundEnabled = false
      view.dragEnabled = true
      view.highlightPerTapEnabled = false
      view.legend.enabled = false
      view.leftAxis.enabled = false
      view.leftAxis.drawGridLinesEnabled = false
      view.leftAxis.drawAxisLineEnabled = false
      view.noDataText = ""
      view.backgroundColor = UIColor.clear
      view.pinchZoomEnabled = false
      view.scaleXEnabled = false
      view.scaleYEnabled = false

      view.setAccessibility(id: .watchlistDetailCandleStickChart)
      view.translatesAutoresizingMaskIntoConstraints = false
      return view
   }()

   private lazy var lineGraphView: LineChartView = {
      let lineChartView = LineChartView()
      lineChartView.xAxis.enabled = false
      lineChartView.rightAxis.enabled = false
      lineChartView.chartDescription?.enabled = false
      lineChartView.drawGridBackgroundEnabled = false
      lineChartView.dragEnabled = true
      lineChartView.highlightPerTapEnabled = false
      lineChartView.legend.enabled = false
      lineChartView.leftAxis.enabled = false
      lineChartView.noDataText = ""
      lineChartView.backgroundColor = UIColor.clear
      lineChartView.pinchZoomEnabled = false
      lineChartView.scaleXEnabled = false
      lineChartView.scaleYEnabled = false

      lineChartView.setAccessibility(id: .watchlistDetailLineChart)
      lineChartView.translatesAutoresizingMaskIntoConstraints = false
      return lineChartView
   }()

   private lazy var detailStackView: UIStackView = {
      let stackView = UIStackView()
      stackView.translatesAutoresizingMaskIntoConstraints = false
      Style.StackView.vertical.apply(to: stackView)
      return stackView
   }()

   private lazy var chartPeriodView: ChartPeriodView = {
      let view = ChartPeriodView(frame: self.view.frame)
      view.translatesAutoresizingMaskIntoConstraints = false

      return view
   }()

   private lazy var dateLabel: UILabel = {
      let label = UILabel()
      label.translatesAutoresizingMaskIntoConstraints = false
      label.isHidden = false
      return label
   }()

   private lazy var loadStateView: LoadStateView = {
      let view = LoadStateView()
      view.translatesAutoresizingMaskIntoConstraints = false
      view.isHidden = true
      return view
   }()

   private lazy var containerView: UIView = {
      let view = UIView()
      view.translatesAutoresizingMaskIntoConstraints = false
      return view
   }()

   private lazy var scrollView: UIView = {
      let view = UIScrollView()
      view.translatesAutoresizingMaskIntoConstraints = false
      return view
   }()

   private lazy var lightHapticGenerator: UIImpactFeedbackGenerator = {
      UIImpactFeedbackGenerator(style: .light)
   }()

   // For passing data for Preview Controller
   var currencyPair: CurrencyPair!

   func layout() {
      navigationItem.leftBarButtonItem = watchlistBarButtonItem
      navigationItem.rightBarButtonItems = [chartTypeBarButtonItem, priceAlertBarButtonItem]
      [pricePercentageLabel].forEach(pricePercentageContainerView.addSubview)
      [pricePercentageContainerView, priceDayLabel].forEach(percentageStackView.addArrangedSubview)
      [graphBackgroudnImageView, candleGraphView, lineGraphView, chartPeriodView].forEach(graphContainerView.addSubview)

      [
         priceLabel, percentageStackView, graphContainerView,
         detailStackView, dateLabel
      ].forEach(containerView.addSubview)

      [containerView].forEach(scrollView.addSubview)

      [loadStateView, scrollView].forEach(view.addSubview)

      NSLayoutConstraint.activate([
         priceLabel.topAnchor.constraint(equalTo: containerView.topAnchor,
                                         constant: Metric.priceLabelTop),
         priceLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor,
                                             constant: Metric.priceLabelLeading),
         priceLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor,
                                              constant: Metric.priceLabelLeading),
         priceLabel.heightAnchor.constraint(equalToConstant: Metric.priceLabelHeight),

         percentageStackView.topAnchor.constraint(equalTo: priceLabel.bottomAnchor),
         percentageStackView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),

         dateLabel.topAnchor.constraint(equalTo: priceLabel.bottomAnchor),
         dateLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),

         graphContainerView.topAnchor.constraint(equalTo: percentageStackView.bottomAnchor,
                                                 constant: Metric.graphContainerTop),
         graphContainerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
         graphContainerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
         graphContainerView.heightAnchor.constraint(equalTo: containerView.widthAnchor,
                                                    multiplier: Metric.graphContainerHeightRatio),

         candleGraphView.centerYAnchor.constraint(equalTo: graphContainerView.centerYAnchor),
         candleGraphView.leadingAnchor.constraint(equalTo: graphContainerView.leadingAnchor),
         candleGraphView.trailingAnchor.constraint(equalTo: graphContainerView.trailingAnchor),
         candleGraphView.heightAnchor.constraint(equalTo: graphContainerView.widthAnchor,
                                                 multiplier: Metric.graphHeightRatio),

         lineGraphView.centerYAnchor.constraint(equalTo: graphContainerView.centerYAnchor),
         lineGraphView.leadingAnchor.constraint(equalTo: graphContainerView.leadingAnchor),
         lineGraphView.trailingAnchor.constraint(equalTo: graphContainerView.trailingAnchor),
         lineGraphView.heightAnchor.constraint(equalTo: graphContainerView.widthAnchor,
                                               multiplier: Metric.graphHeightRatio),

         graphBackgroudnImageView.topAnchor.constraint(equalTo: graphContainerView.topAnchor),
         graphBackgroudnImageView.leadingAnchor.constraint(equalTo: graphContainerView.leadingAnchor),
         graphBackgroudnImageView.trailingAnchor.constraint(equalTo: graphContainerView.trailingAnchor),
         graphBackgroudnImageView.bottomAnchor.constraint(equalTo: graphContainerView.bottomAnchor),

         chartPeriodView.leadingAnchor.constraint(equalTo: graphContainerView.leadingAnchor),
         chartPeriodView.trailingAnchor.constraint(equalTo: graphContainerView.trailingAnchor),
         chartPeriodView.heightAnchor.constraint(equalToConstant: Metric.chartPeriodHeight),
         chartPeriodView.bottomAnchor.constraint(equalTo: graphContainerView.bottomAnchor),

         loadStateView.topAnchor.constraint(equalTo: view.topAnchor),
         loadStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
         loadStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
         loadStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

         containerView.topAnchor.constraint(equalTo: scrollView.topAnchor),
         containerView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
         containerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
         containerView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
         containerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

         scrollView.topAnchor.constraint(equalTo: view.topAnchor),
         scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
         scrollView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor),
         scrollView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor),

         detailStackView.topAnchor.constraint(equalTo: graphContainerView.bottomAnchor,
                                              constant: Metric.stackviewTop),
         detailStackView.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor),
         detailStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
         detailStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

         pricePercentageLabel.centerXAnchor.constraint(equalTo: pricePercentageContainerView.centerXAnchor),
         pricePercentageLabel.centerYAnchor.constraint(equalTo: pricePercentageContainerView.centerYAnchor),

         pricePercentageContainerView.widthAnchor.constraint(equalToConstant: Metric.pricePercentageContainerWidth),
         pricePercentageContainerView.heightAnchor.constraint(equalToConstant: Metric.pricePercentageContainerHeight)
      ])
   }

   override func viewWillDisappear(_ animated: Bool) {
      super.viewWillDisappear(animated)
      disposeBag = DisposeBag()
   }

   override func viewSafeAreaInsetsDidChange() {
      if #available(iOS 11, *) {
         super.viewSafeAreaInsetsDidChange()

         // cannot call in viewWillTransitionToSize, becuase safeAreaInset change after.
         self.chartPeriodView.viewWidth.accept(view.frame.width - view.safeAreaInsets.left - view.safeAreaInsets.right)
      }
   }

   // swiftlint:disable function_body_length
   func bind() {
      rx.viewWillTransitionToSize
         .asDriver(onErrorJustReturn: CGSize.zero)
         .drive(onNext: { [weak self] size in
            self?.chartPeriodView.viewWidth.accept(size.width)
         }).disposed(by: disposeBag)

      view.rx
         .panGesture()
         .when(.ended)
         .subscribe(onNext: { [weak self] _ in
            self?.lineGraphView.highlightValue(nil, callDelegate: true)
            self?.candleGraphView.highlightValue(nil, callDelegate: true)
         })
         .disposed(by: disposeBag)

      let highlightData = lineGraphView
         .rx.chartValueSelected
         .map { $0.2 }
         .asDriver(onErrorJustReturn: Highlight(x: 0.0, y: 0.0, dataSetIndex: 0))

      let candleStickHighlighData = candleGraphView
         .rx.chartValueSelected
         .map { $0.2 }
         .asDriver(onErrorJustReturn: Highlight(x: 0.0, y: 0.0, dataSetIndex: 0))

      let candleStickDataEntry = candleGraphView
         .rx.chartValueSelected
         .map { $0.1 }
         .asDriver(onErrorJustReturn: ChartDataEntry(x: 0.0, y: 0.0))

      let selectedChartPeriod = chartPeriodView.selectedButton
         .asDriver()
         .filterNil()
         .map { $0.chartPeriod }

      let watchlistButtonClicked = watchlistBarButtonItem.rx.tap.asDriver()

      let viewWillAppearDriver = rx.viewWillAppear
         .void()
         .asDriver()

      let output = viewModel.transform(input: .init(watchlistButtonClicked: watchlistButtonClicked,
                                                    selectedChartPeriod: selectedChartPeriod,
                                                    highlightData: highlightData,
                                                    candleStickDataEntry: candleStickDataEntry,
                                                    didTapPriceAlert: priceAlertBarButtonItem.rx.tap.asDriver(),
                                                    viewWillAppearDriver: viewWillAppearDriver,
                                                    didTapchartTypeBarButton: chartTypeBarButtonItem.rx.tap.asDriver()))

      output.watchlistButtonClicked
         .drive()
         .disposed(by: disposeBag)

      output.price
         .drive(priceLabel.rx.text)
         .disposed(by: disposeBag)

      output.currencyDetail
         .map { _ in "currency.detail.inADay".localized() }
         .drive(priceDayLabel.rx.text)
         .disposed(by: disposeBag)

      output.currencyDetail
         .map { String(format: "%@%.2f%%", $0.changePct24hour > 0 ? "+" : "", $0.changePct24hour) }
         .drive(pricePercentageLabel.rx.text)
         .disposed(by: disposeBag)

      output.priceChangePctPriceChange
         .drive(onNext: { [weak self] priceChange in
            self?.pricePercentageContainerView.backgroundColor = priceChange.color
         }).disposed(by: disposeBag)

      output.currencyDetail
         .drive(onNext: { [weak self] detail in
            guard let `self` = self else { return }
            self.priceAlertBarButtonItem.isEnabled = true
            self.statisticViews.forEach { $0.currencyDetail.accept(detail) }
         }).disposed(by: disposeBag)

      output.watchlistDetailData
         .drive(onNext: { [weak self] dataArray in
            guard let `self` = self else { return }
            self.statisticViews = dataArray
               .enumerated()
               .map { index, data in
                  let statisticView = WatchlistDetailStatisticView(watchlistDetailData: data)
                  statisticView.translatesAutoresizingMaskIntoConstraints = false
                  statisticView.index.accept(index)
                  self.detailStackView.addArrangedSubview(statisticView)

                  return statisticView
               }
         }).disposed(by: disposeBag)

      output.candleGraphData
         .drive(onNext: { [weak self] chartData in
            self?.candleGraphView.data = chartData
         }).disposed(by: disposeBag)

      output.lineGraphData
         .drive(onNext: { [weak self] chartData in
            self?.lineGraphView.data = chartData
         }).disposed(by: disposeBag)

      output.historicalPriceResult
         .drive()
         .disposed(by: disposeBag)

      output.selectedPriceText
         .drive(priceLabel.rx.text)
         .disposed(by: disposeBag)

      output.candleStickSelectedPriceText
         .drive(priceLabel.rx.text)
         .disposed(by: disposeBag)

      output.selectedDateText
         .map { Style.AttributedString.watchDetailDateText($0) }
         .drive(dateLabel.rx.attributedText)
         .disposed(by: disposeBag)

      output.historicalPriceIsLoading
         .withLatestFrom(output.graphType) { ($0, $1) }
         .drive(onNext: { [weak self] isLoading, graphType in
            guard let `self` = self else { return }
            if isLoading {
               self.lineGraphView.isHidden = true
               self.candleGraphView.isHidden = true
            } else {
               self.lineGraphView.isHidden = graphType == .candlestick
               self.candleGraphView.isHidden = graphType == .line
            }
         }).disposed(by: disposeBag)

      output.currencyDetailResult
         .drive()
         .disposed(by: disposeBag)

      output.loadStateViewModel.output
         .isContentHidden
         .drive(onNext: { [weak self] isHidden in
            guard let `self` = self else {
               return
            }
            self.containerView.isHidden = isHidden
            self.chartTypeBarButtonItem.isEnabled = !isHidden
            self.chartTypeBarButtonItem.tintColor = isHidden ? UIColor.clear : Color.tealish
         })
         .disposed(by: disposeBag)

      output.didTapPriceAlert
         .drive()
         .disposed(by: disposeBag)

      output.isUpdateAlert
         .drive(onNext: { [weak self] isUpdateAlert in
            self?.priceAlertBarButtonItem.image = isUpdateAlert ? Image.editPriceAlertIcon.resource
               : Image.priceAlertIcon.resource
         })
         .disposed(by: disposeBag)

      output.graphType
         .map { $0.opposite.image }
         .drive(onNext: { [weak self] image in
            self?.chartTypeBarButtonItem.image = image
         })
         .disposed(by: disposeBag)

      output.didTapChartTypeBarButton
         .do(onNext: { [weak self] chartType in
            self?.lineGraphView.isHidden = (chartType == .candlestick)
            self?.candleGraphView.isHidden = (chartType == .line)
         })
         .map { $0.opposite.image }
         .drive(onNext: { [weak self] image in
            self?.chartTypeBarButtonItem.image = image
         })
         .disposed(by: disposeBag)

      let graphHighlighWithValue = Driver.merge(highlightData, candleStickHighlighData)
         .map { _ in true }

      graphHighlighWithValue
         .drive(percentageStackView.rx.isHidden)
         .disposed(by: disposeBag)

      graphHighlighWithValue
         .void()
         .drive(onNext: lightHapticGenerator.impactOccurred)
         .disposed(by: disposeBag)

      graphHighlighWithValue
         .not()
         .drive(dateLabel.rx.isHidden)
         .disposed(by: disposeBag)

      let highlightHasValue = highlightData
         .map { _ in true }

      highlightHasValue
         .drive(onNext: { [weak self] _ in
            self?.priceLabel.textColor = Color.warmGreyFour
         })
         .disposed(by: disposeBag)

      let candleStickHighlightWithValue = candleStickHighlighData
         .map { _ in true }

      candleStickHighlightWithValue
         .drive(onNext: { [weak self] _ in
            self?.priceLabel.font = self?.priceLabel.font.withSize(16.0)
         })
         .disposed(by: disposeBag)

      let lineGraphHighlightEnded = lineGraphView
         .rx.chartValueUnselected
         .asDriver(onErrorJustReturn: lineGraphView)
         .map { _ in true }

      let candleStickGraphHighlightEnded = candleGraphView
         .rx.chartValueUnselected
         .asDriver(onErrorJustReturn: candleGraphView)
         .map { _ in true }

      let highlightEnded = Driver.merge(lineGraphHighlightEnded, candleStickGraphHighlightEnded)

      highlightEnded
         .not()
         .drive(percentageStackView.rx.isHidden)
         .disposed(by: disposeBag)

      highlightEnded
         .withLatestFrom(output.price)
         .drive(onNext: { [weak self] priceText in
            self?.priceLabel.text = priceText
            self?.dateLabel.isHidden = true
         })
         .disposed(by: disposeBag)

      highlightEnded
         .withLatestFrom(ThemeProvider.current)
         .drive(onNext: { [weak self] theme in
            guard let `self` = self else { return }
            theme.watchDetailPriceLabel.apply(to: self.priceLabel)
         })
         .disposed(by: disposeBag)

      loadStateView.bind(state: output.loadStateViewModel)

      // Theme
      ThemeProvider.current
         .drive(onNext: { [weak self] theme in
            guard let `self` = self else { return }
            theme.view.apply(to: self.view)
            theme.watchDetailPriceLabel.apply(to: self.priceLabel)
            theme.watchDetailPriceDayLabel.apply(to: self.priceDayLabel)

            self.graphBackgroudnImageView.image = theme == .light ?
               Image.lightChartBackground.resource : Image.darkChartBackground.resource
         })
         .disposed(by: disposeBag)

      let orientationDidChange = NotificationCenter.default
         .rx.notification(UIDevice.orientationDidChangeNotification)
         .asDriver(onErrorJustReturn:
            Notification(name: UIDevice.orientationDidChangeNotification))
         .void()

      Driver.combineLatest(orientationDidChange.startWith(()), ThemeProvider.current.asDriver())
         .drive(onNext: { [weak self] data in
            guard let `self` = self else { return }

            let isLandscape = !(UIDevice.current.orientation.isPortrait ||
               UIApplication.shared.statusBarOrientation == .portrait)
            let theme = data.1

            self.update(attributedScreenName: theme.watchListTitle(base: output.currencyPair.baseCurrency.symbol,
                                                                   quote: output.currencyPair.quoteCurrency.symbol,
                                                                   exchange: output.currencyPair.exchange
                                                                      .localizedFullname,
                                                                   isLandscape: isLandscape),
                        navigationItem: self.navigationItem)
         })
         .disposed(by: disposeBag)
   }
}
