//
//  ChartData.swift
//  App
//
//  Created by Hong on 19/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Charts
import Foundation

enum DataSet {
   case negative
   case positive

   var label: String {
      switch self {
      case .negative:
         return "Negative"
      case .positive:
         return "Positive"
      }
   }

   var color: UIColor {
      switch self {
      case .negative:
         return Color.PriceChange.negative
      case .positive:
         return Color.PriceChange.positive
      }
   }

   var fillAlpha: CGFloat {
      return 0.47
   }

   func generateDataSet(data: [ChartDataEntry], isFillEnabled: Bool) -> LineChartDataSet {
      let dataSet = LineChartDataSet(entries: data, label: label)

      dataSet.mode = .linear
      dataSet.drawCirclesEnabled = false
      dataSet.setColor(color)

      dataSet.fillColor = color
      dataSet.fillAlpha = fillAlpha
      dataSet.drawValuesEnabled = false
      dataSet.drawFilledEnabled = isFillEnabled
      dataSet.drawHorizontalHighlightIndicatorEnabled = false
      dataSet.drawVerticalHighlightIndicatorEnabled = false
      dataSet.fillFormatter = CustomLineFormatter()
      return dataSet
   }
}

class CustomLineFormatter: IFillFormatter {
   func getFillLinePosition(dataSet: ILineChartDataSet, dataProvider: LineChartDataProvider) -> CGFloat {
      return 0.0
   }
}
