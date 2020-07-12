//
//  ChartDataHelper.swift
//  App
//
//  Created by Kok Hong Choo on 8/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Charts
import Domain
import Foundation

enum ChartDataHelper {
   static func convertToChartData(from data: [HistoricalPrice]) -> ChartData {
      let inputArray = data

      guard let firstPrice = inputArray.first?.close, inputArray.count > 1 else {
         return LineChartData()
      }

      var dataSets = [LineChartDataSet]()
      var chartEntry = [ChartDataEntry]()

      // Determine trend of graph
      var isPositiveFlag = inputArray[1].close > 0

      for i in 0..<inputArray.count {
         let historicalPrice = inputArray[i]
         let x = Double(historicalPrice.time)
         let y = historicalPrice.close - firstPrice

         // If there is a -ve to +ve changes Vice Versa
         if (y >= 0 && !isPositiveFlag) || (y < 0 && isPositiveFlag) {
            let dataSetMode = isPositiveFlag ? DataSet.positive : DataSet.negative

            // Append Zero Y to smoothen the graph when changes from -ve to +v. Vice versa
            let zeroEntry = ChartDataEntry(x: x, y: 0)
            chartEntry.append(zeroEntry)
            dataSets.append(dataSetMode.generateDataSet(data: chartEntry, isFillEnabled: false))

            chartEntry = [zeroEntry]
            isPositiveFlag = !isPositiveFlag
         }

         chartEntry.append(ChartDataEntry(x: x, y: y))

         if i == inputArray.count - 1 {
            let dataSetMode = isPositiveFlag ? DataSet.positive : DataSet.negative
            dataSets.append(dataSetMode.generateDataSet(data: chartEntry, isFillEnabled: false))
         }
      }

      // Always Append last array to dataset
      let dataSetMode = isPositiveFlag ? DataSet.positive : DataSet.negative
      dataSets.append(dataSetMode.generateDataSet(data: chartEntry, isFillEnabled: false))

      let chartData = LineChartData(dataSets: dataSets)

      return chartData
   }

   static func convertToDetailCandleChartData(from data: [HistoricalPrice]) -> ChartData {
      let dataEntry: [CandleChartDataEntry] = data
         .enumerated()
         .map { index, element in
            CandleChartDataEntry(x: Double(index),
                                 shadowH: element.high,
                                 shadowL: element.low,
                                 open: element.open,
                                 close: element.close,
                                 data: element as AnyObject)
         }

      let dataSet = CandleChartDataSet(entries: dataEntry, label: "Candle Stick")
      dataSet.drawIconsEnabled = false
      dataSet.decreasingColor = Color.Candlestick.negative
      dataSet.decreasingFilled = true
      dataSet.increasingColor = Color.Candlestick.positive
      dataSet.increasingFilled = true
      dataSet.neutralColor = Color.warmGrey
      dataSet.shadowColorSameAsCandle = true
      dataSet.valueTextColor = UIColor.clear
      dataSet.highlightColor = Color.tealish
      dataSet.drawHorizontalHighlightIndicatorEnabled = false
      dataSet.highlightLineWidth = 1.0
      let chartData = CandleChartData(dataSets: [dataSet])

      return chartData
   }

   static func convertToDetailLineChartData(from data: [HistoricalPrice], theme: Theme) -> ChartData {
      let dataEntry: [ChartDataEntry] = data
         .map { element in
            ChartDataEntry(x: Double(element.time), y: element.close)
         }

      let dataSet = LineChartDataSet(entries: dataEntry, label: "Line Chart")
      dataSet.mode = .linear
      dataSet.drawCirclesEnabled = false
      dataSet.setColor(theme.watchDetailLineChartColor)
      dataSet.lineWidth = 1.5
      dataSet.drawValuesEnabled = false
      dataSet.drawHorizontalHighlightIndicatorEnabled = false
      dataSet.highlightColor = Color.tealish
      dataSet.highlightLineWidth = 1.0
      let chartData = LineChartData(dataSets: [dataSet])

      return chartData
   }
}
