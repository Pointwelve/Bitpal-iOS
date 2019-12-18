//
//  Charts+Rx.swift
//  App
//
//  Created by Kok Hong Choo on 24/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Charts
import Foundation
import RxCocoa
import RxSwift
class ChartsDelegateProxy: DelegateProxy<ChartViewBase, ChartViewDelegate>, ChartViewDelegate, DelegateProxyType {
   /// Typed parent object.
   public private(set) weak var chart: ChartViewBase?

   /// - parameter tabBar: Parent object for delegate proxy.
   public init(chart: ParentObject) {
      self.chart = chart
      super.init(parentObject: chart, delegateProxy: ChartsDelegateProxy.self)
   }

   // Register known implementations
   public static func registerKnownImplementations() {
      register { ChartsDelegateProxy(chart: $0) }
   }

   static func currentDelegate(for object: ChartViewBase) -> ChartViewDelegate? {
      return object.delegate
   }

   static func setCurrentDelegate(_ delegate: ChartViewDelegate?, to object: ChartViewBase) {
      object.delegate = delegate
   }
}

extension Reactive where Base: ChartViewBase {
   public var delegate: DelegateProxy<ChartViewBase, ChartViewDelegate> {
      return ChartsDelegateProxy.proxy(for: base)
   }

   public var chartValueSelected: Observable<(ChartViewBase, ChartDataEntry, Highlight)> {
      return delegate.methodInvoked(#selector(ChartViewDelegate.chartValueSelected(_:entry:highlight:)))
         .map { params in
            // swiftlint:disable force_cast
            let chartViewBase = params[0] as! ChartViewBase
            let dataEntry = params[1] as! ChartDataEntry
            let highlight = params[2] as! Highlight
            return (chartViewBase, dataEntry, highlight)
         }
   }

   public var chartValueUnselected: Observable<ChartViewBase> {
      return delegate.methodInvoked(#selector(ChartViewDelegate.chartValueNothingSelected(_:)))
         .map { params in
            // swiftlint:disable force_cast
            let chartViewBase = params[0] as! ChartViewBase
            return chartViewBase
         }
   }
}
