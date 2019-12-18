//
//  Image.swift
//  App
//
//  Created by Ryne Cheow on 25/3/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import UIKit

protocol ImageType {
   var resource: UIImage { get }
   var resourceWhileSelected: UIImage? { get }
}

enum Image: ImageType {
   // Logo
   case appLogo

   // Tabs
   case watchlist
   case portfolio
   case alerts
   case settings

   // Icons
   case backIcon
   case nextIcon
   case closeIcon
   case plusIcon
   case deleteIcon
   case lineChartIcon
   case watchListIcon
   case candleStickIcon
   case priceAlertIcon
   case editPriceAlertIcon

   // Background
   case lightChartBackground
   case darkChartBackground

   var resource: UIImage {
      switch self {
      case .appLogo:
         return #imageLiteral(resourceName: "Bitpal Logo")
      case .watchlist:
         return #imageLiteral(resourceName: "Watchlist Icon")
      case .portfolio:
         return #imageLiteral(resourceName: "Portfolio Icon")
      case .alerts:
         return #imageLiteral(resourceName: "Alerts Icon")
      case .settings:
         return #imageLiteral(resourceName: "Settings Icon")
      case .backIcon:
         return #imageLiteral(resourceName: "Icon Right Arrow")
      case .nextIcon:
         return #imageLiteral(resourceName: "Icon Left Arrow")
      case .closeIcon:
         return #imageLiteral(resourceName: "Cross Icon")
      case .plusIcon:
         return #imageLiteral(resourceName: "Plus Icon")
      case .deleteIcon:
         return #imageLiteral(resourceName: "Delete Icon")
      case .lineChartIcon:
         return #imageLiteral(resourceName: "Line Chart Icon")
      case .candleStickIcon:
         return #imageLiteral(resourceName: "Candle Stick Icon")
      case .watchListIcon:
         return #imageLiteral(resourceName: "Watch List Icon")
      case .priceAlertIcon:
         return #imageLiteral(resourceName: "Price Alert Icon")
      case .editPriceAlertIcon:
         return #imageLiteral(resourceName: "Edit Price Alert Icon")
      case .lightChartBackground:
         return #imageLiteral(resourceName: "Light Chart Background")
      case .darkChartBackground:
         return #imageLiteral(resourceName: "Dark Chart Background")
      }
   }

   var resourceWhileSelected: UIImage? {
      switch self {
      case .watchlist:
         return #imageLiteral(resourceName: "Watchlist Icon")
      case .portfolio:
         return #imageLiteral(resourceName: "Portfolio Icon")
      case .settings:
         return #imageLiteral(resourceName: "Settings Icon")
      default:
         return nil
      }
   }
}
