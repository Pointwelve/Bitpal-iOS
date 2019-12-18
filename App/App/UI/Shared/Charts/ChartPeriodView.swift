//
//  ChartPeriodView.swift
//  App
//
//  Created by Kok Hong Choo on 21/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxCocoa
import RxSwift

final class ChartPeriodButton: UIButton {
   let chartPeriod: ChartPeriod
   var isButtonSelected: Bool {
      didSet {
         DispatchQueue.main.async {
            let color = self.isButtonSelected ? self.selectedColor : Color.tealish
            let title = Style.AttributedString.chartPeriodText(self.chartPeriod.name, color: color)

            self.setAttributedTitle(title, for: .normal)
         }
      }
   }

   var selectedColor: UIColor {
      didSet {
         DispatchQueue.main.async {
            // Only change selectedColor
            if self.isButtonSelected {
               let title = Style.AttributedString.chartPeriodText(self.chartPeriod.name, color: self.selectedColor)

               self.setAttributedTitle(title, for: .normal)
            }
         }
      }
   }

   init(chartPeriod: ChartPeriod, frame: CGRect) {
      self.chartPeriod = chartPeriod
      isButtonSelected = false
      selectedColor = Color.white
      super.init(frame: frame)
   }

   required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
   }
}

final class ChartPeriodView: UIView, BaseViewType, Bindable {
   private enum Metric {
      static let paddingLeadingTrailing: CGFloat = 14.0
      static let buttonHeight: CGFloat = 28.0
      static let viewHeight: CGFloat = 30.0
      static let indicatorHeight: CGFloat = 2.0
      static let indicatorLeadingTrailing: CGFloat = 6.0
      static let indicatorAnimationDuration: TimeInterval = 0.2
   }

   private let sizeChangeDisposeBag = DisposeBag()
   var disposeBag = DisposeBag()
   let viewWidth = BehaviorRelay<CGFloat?>(value: nil)

   private var chartPeriods: [ChartPeriod]
   private var chartPeriodButtons: [ChartPeriodButton] = []

   private lazy var indicatorView: UIView = {
      let view = UIView()
      Style.View.background(with: Color.tealish).apply(to: view)
      return view
   }()

   let selectedButton = BehaviorRelay<ChartPeriodButton?>(value: nil)

   init(chartPeriods: [ChartPeriod] = ChartPeriod.allPeriods, frame: CGRect) {
      self.chartPeriods = chartPeriods
      super.init(frame: frame)
      layout()
      bindViewRotation()
      bind()
   }

   required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
   }

   private func relayoutViews() {
      var currentX = Metric.paddingLeadingTrailing
      let buttonWidth = (frame.width - (2 * Metric.paddingLeadingTrailing)) / CGFloat(chartPeriods.count)
      let indicatorWidth = buttonWidth - (2 * Metric.indicatorLeadingTrailing)
      let indicatorOriginX = currentX + Metric.indicatorLeadingTrailing
      let indicatorY = Metric.viewHeight - Metric.indicatorHeight

      indicatorView.frame = CGRect(x: indicatorOriginX,
                                   y: indicatorY,
                                   width: indicatorWidth,
                                   height: Metric.indicatorHeight)

      chartPeriodButtons = chartPeriods.map { [weak self] period in
         let rect = CGRect(x: currentX, y: 0, width: buttonWidth, height: Metric.buttonHeight)
         let button = ChartPeriodButton(chartPeriod: period, frame: rect)
         let title = Style.AttributedString.chartPeriodText(period.name)
         button.setAttributedTitle(title, for: .normal)

         self?.addSubview(button)
         currentX += buttonWidth
         return button
      }
   }

   func layout() {
      addSubview(indicatorView)
      relayoutViews()
   }

   func bindViewRotation() {
      viewWidth.asDriver()
         .filterNil()
         .drive(onNext: { [weak self] width in
            guard let `self` = self else { return }
            self.chartPeriodButtons.forEach { $0.removeFromSuperview() }
            self.frame = CGRect(x: self.frame.origin.x,
                                y: self.frame.origin.y,
                                width: width,
                                height: self.frame.height)
            self.relayoutViews()
            self.disposeBag = DisposeBag()
            self.bind()
            self.chartPeriodButtons.forEach { $0.isButtonSelected = false }

            let button = self.chartPeriodButtons.first { $0.chartPeriod == self.selectedButton.value?.chartPeriod }

            if let button = button {
               button.isButtonSelected = true
               self.animateIndicatorView(with: button)
            }
         }).disposed(by: sizeChangeDisposeBag)
   }

   func bind() {
      ThemeProvider.current
         .drive(onNext: { [weak self] theme in
            guard let `self` = self else { return }
            self.chartPeriodButtons.forEach { button in
               button.selectedColor = theme.chartPeriodColor
            }
         }).disposed(by: disposeBag)

      chartPeriodButtons.forEach { [weak self] button in
         guard let `self` = self else {
            return
         }

         button.rx.tap
            .asDriver()
            .map { button }
            .drive(self.selectedButton)
            .disposed(by: self.disposeBag)
      }

      selectedButton.asDriver()
         .filterNil()
         .drive(onNext: { [weak self] button in
            guard let `self` = self else { return }
            // Reset all selected states
            self.chartPeriodButtons.forEach { $0.isButtonSelected = false }
            button.isButtonSelected = true

            self.animateIndicatorView(with: button)
         }).disposed(by: disposeBag)

      if selectedButton.value == nil {
         selectedButton.accept(chartPeriodButtons.first)
      }
   }

   private func animateIndicatorView(with button: UIButton) {
      // For Indicator View
      UIView.animate(withDuration: Metric.indicatorAnimationDuration) {
         var rect = self.indicatorView.frame
         rect.origin.x = button.frame.origin.x + Metric.indicatorLeadingTrailing
         self.indicatorView.frame = rect
      }
   }
}
