//
//  TodayTableViewCell.swift
//  App
//
//  Created by James Lai on 6/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import RxCocoa
import RxSwift
import UIKit

final class TodayTableViewModel {
   struct Input {
      let currencyPairDriver: Driver<CurrencyPair>
      let getCurrencyDetailsActionDriver: Driver<(GetCurrencyDetailRequest) -> CurrencyDetailUseCaseCoordinator>
   }

   struct Output {
      let currencyDetailsRequestDriver: Driver<Void>
      let exchange: Driver<String>
      let baseCurrency: Driver<String>
      let quoteCurrency: Driver<String>
      let changePct: Driver<String>
      let pctViewColor: Driver<UIColor>
   }

   func transform(input: Input) -> Output {
      let exchange = input.currencyPairDriver
         .map { $0.exchange.name.localized() }
      let baseCurrency = input.currencyPairDriver
         .map { $0.baseCurrency.symbol }

      let currencyDetail = BehaviorRelay<CurrencyDetail?>(value: nil)
      let currencyDetailError = BehaviorRelay<Error?>(value: nil)

      let currencyDetailsRequestDriver = input.getCurrencyDetailsActionDriver
         .withLatestFrom(input.currencyPairDriver) { ($0, $1) }
         .flatMap { (requestAction, currencyPair) -> Driver<Void> in
            requestAction(GetCurrencyDetailRequest(currencyPair: currencyPair))
               .getResult()
               .asDriver(onErrorJustReturn: .failure(.error(UseCaseError.executionFailed)))
               .do(onNext: { result in
                  switch result.flattened {
                  case let .content(content):
                     switch content {
                     case let .with(coordinator, condition):
                        switch condition {
                        case .full:
                           currencyDetailError.accept(nil)
                           currencyDetail.accept(coordinator.currencyDetail)
                        default:
                           break
                        }
                     }
                  case let .failure(failure):
                     switch failure {
                     case let .error(error):
                        currencyDetailError.accept(error)
                     default:
                        break
                     }
                  default:
                     break
                  }
               })
               .void()
         }

      let quoteCurrency = Driver.merge([
         currencyDetail.asDriver().filterNil().map { "\($0.price.formatUsingSignificantDigits()) \($0.toCurrency)" },
         currencyDetailError.asDriver().filterNil().map { _ in "widget.error".localized() }
      ])
      let changePct = currencyDetail.asDriver().filterNil().map { $0.changePct24hour }
      let changePctString = changePct.map { String(format: "%@%.2f%%", $0 > 0 ? "+" : "", $0) }
      let pctViewColor = changePct.map { $0.priceChangeIn24HPct().color }

      return Output(currencyDetailsRequestDriver: currencyDetailsRequestDriver,
                    exchange: exchange,
                    baseCurrency: baseCurrency,
                    quoteCurrency: quoteCurrency,
                    changePct: changePctString,
                    pctViewColor: pctViewColor)
   }
}

class TodayTableViewCell: UITableViewCell {
   private enum Metric {
      static let exchangeLabelTop: CGFloat = 10.0

      static let percentageViewWidth: CGFloat = 60.0
      static let percentageViewHeight: CGFloat = 24.0
      static let percentageCornerRadius: CGFloat = 3.0

      static let quoteCurrencyLabelWidth: CGFloat = 176.0
      static let quoteCurrencyTrailing: CGFloat = -10.0
   }

   var viewModel: TodayTableViewModel!

   var disposeBag: DisposeBag!

   var currencyPair = BehaviorRelay<CurrencyPair?>(value: nil)

   var getCurrencyDetailsAction = BehaviorRelay<((GetCurrencyDetailRequest) -> CurrencyDetailUseCaseCoordinator)?>(value: nil)

   public static let identifier = String(describing: TodayTableViewCell.self)

   private lazy var exchangeLabel: UILabel = {
      let label = UILabel()
      label.translatesAutoresizingMaskIntoConstraints = false
      Style.Label.exchangeLabel.apply(to: label)

      return label
   }()

   private lazy var baseCurrencyLabel: UILabel = {
      let label = UILabel()
      label.translatesAutoresizingMaskIntoConstraints = false
      Style.Label.baseLabel.apply(to: label)

      return label
   }()

   private lazy var priceLabel: UILabel = {
      let label = UILabel()
      label.translatesAutoresizingMaskIntoConstraints = false
      Style.Label.priceLabel.apply(to: label)

      return label
   }()

   private lazy var percentageLabel: UILabel = {
      let label = UILabel()
      label.translatesAutoresizingMaskIntoConstraints = false
      Style.Label.percentageLabel.apply(to: label)

      return label
   }()

   private lazy var percentageLabelView: UIView = {
      let view = UIView()
      view.translatesAutoresizingMaskIntoConstraints = false
      Style.View.radius(with: Metric.percentageCornerRadius).apply(to: view)

      return view
   }()

   override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
      super.init(style: style, reuseIdentifier: reuseIdentifier)
      viewModel = TodayTableViewModel()
      disposeBag = DisposeBag()
      layout()
      bind()
   }

   required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
   }

   func layout() {
      [exchangeLabel, baseCurrencyLabel, percentageLabelView, priceLabel].forEach(contentView.addSubview)
      [percentageLabel].forEach(percentageLabelView.addSubview)

      NSLayoutConstraint.activate([
         exchangeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Metric.exchangeLabelTop),
         exchangeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),

         baseCurrencyLabel.topAnchor.constraint(equalTo: exchangeLabel.bottomAnchor),
         baseCurrencyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),

         percentageLabelView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
         percentageLabelView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
         percentageLabelView.widthAnchor.constraint(equalToConstant: Metric.percentageViewWidth),
         percentageLabelView.heightAnchor.constraint(equalToConstant: Metric.percentageViewHeight),

         percentageLabel.centerXAnchor.constraint(equalTo: percentageLabelView.centerXAnchor),
         percentageLabel.centerYAnchor.constraint(equalTo: percentageLabelView.centerYAnchor),

         priceLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
         priceLabel.trailingAnchor.constraint(equalTo: percentageLabelView.leadingAnchor, constant: Metric.quoteCurrencyTrailing),
         priceLabel.widthAnchor.constraint(equalToConstant: Metric.quoteCurrencyLabelWidth)
      ])
   }

   func bind() {
      let output = viewModel.transform(input: .init(currencyPairDriver: currencyPair.asDriver().filterNil(),
                                                    getCurrencyDetailsActionDriver: getCurrencyDetailsAction.asDriver().filterNil()))

      output.exchange.drive(exchangeLabel.rx.text).disposed(by: disposeBag)
      output.baseCurrency.drive(baseCurrencyLabel.rx.text).disposed(by: disposeBag)

      output.quoteCurrency.startWith("- \(currencyPair.value?.quoteCurrency.name ?? "")")
         .drive(priceLabel.rx.text)
         .disposed(by: disposeBag)

      output.changePct.startWith("-")
         .drive(percentageLabel.rx.text)
         .disposed(by: disposeBag)

      output.pctViewColor.startWith(Color.warmGrey)
         .drive(onNext: { self.percentageLabelView.backgroundColor = $0 })
         .disposed(by: disposeBag)

      output.currencyDetailsRequestDriver
         .drive()
         .disposed(by: disposeBag)
   }
}
