//
//  ThemeStyle.swift
//  App
//
//  Created by Li Hao Lai on 4/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Presentr
import RxCocoa
import RxSwift
import UIKit

// swiftlint:disable file_length
extension Theme {
   var navigationBar: UIViewStyle<UINavigationBar> {
      switch self {
      case .dark:
         return Style.NavigationBar.dark

      case .light:
         return Style.NavigationBar.light
      }
   }

   var tabBar: UIViewStyle<UITabBar> {
      switch self {
      case .dark:
         return Style.TabBar.dark

      case .light:
         return Style.TabBar.light
      }
   }

   var view: UIViewStyle<UIView> {
      switch self {
      case .dark:
         return Style.View.dark

      case .light:
         return Style.View.light
      }
   }

   var exchangeTitleView: UIViewStyle<UIView> {
      switch self {
      case .dark:
         return Style.View.darkTwo

      case .light:
         return Style.View.whiteThree
      }
   }

   var tableView: UIViewStyle<UITableView> {
      switch self {
      case .dark:
         return Style.TableView.dark

      case .light:
         return Style.TableView.light
      }
   }

   var cellOne: UIViewStyle<UITableViewCell> {
      switch self {
      case .dark:
         return Style.Cell.darkThree

      case .light:
         return Style.Cell.lightTwo
      }
   }

   var cellTwo: UIViewStyle<UITableViewCell> {
      switch self {
      case .dark:
         return Style.Cell.dark

      case .light:
         return Style.Cell.light
      }
   }

   var priceList: UIViewStyle<UILabel> {
      switch self {
      case .dark:
         return Style.Label.priceListWhiteText

      case .light:
         return Style.Label.priceListBlackText
      }
   }

   var priceListExchange: UIViewStyle<UILabel> {
      switch self {
      case .dark:
         return Style.Label.darkPriceListExchangeText

      case .light:
         return Style.Label.lightPriceListExchangeText
      }
   }

   var headerBaseFullname: UIViewStyle<UILabel> {
      switch self {
      case .dark:
         return Style.Label.headerBaseFullnameWhiteText

      case .light:
         return Style.Label.headerBaseFullnameBlackText
      }
   }

   var backgroundErrorTitle: UIViewStyle<UILabel> {
      switch self {
      case .dark:
         return Style.Label.darkBackgorundErrorTitle

      case .light:
         return Style.Label.lightBackgorundErrorTitle
      }
   }

   var backgroundErrorMessage: UIViewStyle<UILabel> {
      switch self {
      case .dark:
         return Style.Label.darkBackgroundErrorMessage

      case .light:
         return Style.Label.lightBackgroundErrorMessage
      }
   }

   var settingsTitleLabel: UIViewStyle<UILabel> {
      switch self {
      case .dark:
         return Style.Label.darkSettingsTitleLabel

      case .light:
         return Style.Label.lightSettingsTitleLabel
      }
   }

   var termsCompanyTitleLabel: UIViewStyle<UILabel> {
      switch self {
      case .dark:
         return Style.Label.darkTermsCompanyTitleLabel

      case .light:
         return Style.Label.lightTermsCompanyTitleLabel
      }
   }

   var settingsVersionLabel: UIViewStyle<UILabel> {
      switch self {
      case .dark:
         return Style.Label.darkSettingsVersionLabel

      case .light:
         return Style.Label.lightSettingsVersionLabel
      }
   }

   var temsAndConditionsTextView: UIViewStyle<UITextView> {
      switch self {
      case .dark:
         return Style.TextView.darkTermsAndCondition

      case .light:
         return Style.TextView.lightTermsAndCondition
      }
   }

   var search: UIViewStyle<UITextField> {
      switch self {
      case .dark:
         return Style.TextField.darkSearch

      case .light:
         return Style.TextField.lightSearch
      }
   }

   // MARK: - Watch List Cell

   var priceListExchangeLabel: UIViewStyle<UILabel> {
      return Style.Label.priceListExchangeLabel
   }

   var pricePercentageLabel: UIViewStyle<UILabel> {
      return Style.Label.pricePercentageLabel
   }

   var priceListPriceLabel: UIViewStyle<UILabel> {
      switch self {
      case .dark:
         return Style.Label.priceListPriceWhiteText
      case .light:
         return Style.Label.priceListPriceDarkThreeText
      }
   }

   var priceListBaseLabel: UIViewStyle<UILabel> {
      switch self {
      case .dark:
         return Style.Label.priceListBaseCurrencyWhiteText
      case .light:
         return Style.Label.priceListBaseCurrencyBlackText
      }
   }

   var priceListQuoteLabel: UIViewStyle<UILabel> {
      return Style.Label.priceListGrayText
   }

   var priceListGraphZeroLineColor: UIColor {
      switch self {
      case .dark:
         return Color.greyishThree
      case .light:
         return Color.dark
      }
   }

   func priceListNextArrowImageView(image: UIImage) -> UIViewStyle<UIImageView> {
      return Style.ImageView.tint(with: Color.warmGreyThree, image: image)
   }

   // MARK: - Watch List Detail

   func watchListTitle(base: String, quote: String, exchange: String, isLandscape: Bool = false) -> NSAttributedString {
      let baseCurrencyColor = self == .dark ? Color.white : Color.charcoalGrey
      let quoteCurrencyColor = Color.coolGrey
      let exchangeColor = self == .dark ? Color.coolGrey : Color.charcoalGrey

      let baseString = Style.AttributedString.watchlistDetailTitleFirstLine("\(base) ",
                                                                            color: baseCurrencyColor)

      let quoteString = Style.AttributedString.watchlistDetailTitleFirstLine(quote,
                                                                             color: quoteCurrencyColor)

      let exchangeRawString = isLandscape ? "  \(exchange)" : "\n\(exchange)"
      let exchangeString = Style.AttributedString.watchlistDetailTitleSecondLine(exchangeRawString,
                                                                                 color: exchangeColor)

      return baseString + quoteString + exchangeString
   }

   var watchDetailPriceLabel: UIViewStyle<UILabel> {
      switch self {
      case .dark:
         return Style.Label.priceDetailDarkLabel
      case .light:
         return Style.Label.priceDetailLightLabel
      }
   }

   var watchDetailPricePctLabel: UIViewStyle<UILabel> {
      switch self {
      case .dark:
         return Style.Label.priceDetailDarkPctLabel
      case .light:
         return Style.Label.priceDetailLightPctLabel
      }
   }

   var watchDetailPriceDayLabel: UIViewStyle<UILabel> {
      switch self {
      case .dark:
         return Style.Label.priceDetailDarkDayLabel
      case .light:
         return Style.Label.priceDetailLightDayLabel
      }
   }

   func watchDetailStatisticTitle(_ text: String) -> NSAttributedString {
      switch self {
      case .dark:
         return text.attributedString(withLetterSpacing: 0.5,
                                      textAlignment: .left,
                                      textColor: Color.coolGreyTwo,
                                      font: Font.semiBold10)
      case .light:
         return text.attributedString(withLetterSpacing: 0.5,
                                      textAlignment: .left,
                                      textColor: Color.darkThree66,
                                      font: Font.semiBold10)
      }
   }

   var watchDetailStatisticDetailLabel: UIViewStyle<UILabel> {
      switch self {
      case .dark:
         return Style.Label.priceDetailDarkStatisticDetailLabel
      case .light:
         return Style.Label.priceDetailLightStatisticDetailLabel
      }
   }

   var watchDetailStatisticColorOne: UIColor {
      switch self {
      case .dark:
         return Color.dark
      case .light:
         return Color.white
      }
   }

   var watchDetailStatisticColorTwo: UIColor {
      switch self {
      case .dark:
         return Color.darkThree
      case .light:
         return Color.whiteSix
      }
   }

   var watchDetailLineChartColor: UIColor {
      switch self {
      case .dark:
         return Color.whiteFive
      case .light:
         return Color.dark
      }
   }

   var chartPeriodColor: UIColor {
      switch self {
      case .dark:
         return Color.white
      case .light:
         return Color.dark
      }
   }

   var watchDetailDateLabel: UIViewStyle<UILabel> {
      switch self {
      case .dark:
         return Style.Label.priceDetailDarkStatisticDetailLabel
      case .light:
         return Style.Label.priceDetailLightStatisticDetailLabel
      }
   }

   var popup: UIViewStyle<UIView> {
      switch self {
      case .dark:
         return Style.View.popupDark

      case .light:
         return Style.View.popupLight
      }
   }

   var popupBackground: UIViewStyle<UIVisualEffectView> {
      switch self {
      case .dark:
         return Style.View.popupBackgroundDark

      case .light:
         return Style.View.popupBackgroundLight
      }
   }

   var popuoTitle: UIViewStyle<UILabel> {
      switch self {
      case .dark:
         return Style.Label.popupTitleDark

      case .light:
         return Style.Label.popupTitleLight
      }
   }

   var popupMessage: UIViewStyle<UILabel> {
      switch self {
      case .dark:
         return Style.Label.popupMessageDark

      case .light:
         return Style.Label.popupMessageLight
      }
   }

   var popupDefault: UIViewStyle<UIButton> {
      switch self {
      case .dark:
         return Style.Button.popupDefaultDark

      case .light:
         return Style.Button.popupDefaultLight
      }
   }

   var popupCancel: UIViewStyle<UIButton> {
      switch self {
      case .dark:
         return Style.Button.popupCancelDark

      case .light:
         return Style.Button.popupCancelLight
      }
   }

   var viewThree: UIViewStyle<UIView> {
      switch self {
      case .dark:
         return Style.View.darkThree

      case .light:
         return Style.View.light
      }
   }

   var createAlertButton: UIViewStyle<UIButton> {
      switch self {
      case .dark:
         return Style.Button.createAlertDark

      case .light:
         return Style.Button.createAlertLight
      }
   }

   var createAlertTextField: UIViewStyle<UITextField> {
      switch self {
      case .dark:
         return Style.TextField.alertPriceDark

      case .light:
         return Style.TextField.alertPriceLight
      }
   }

   var createAlertPriceSymbol: UIViewStyle<UILabel> {
      switch self {
      case .dark:
         return Style.Label.priceAlertSymbolDark

      case .light:
         return Style.Label.priceAlertSymbolLight
      }
   }

   var createAlertGreaterButton: UIViewStyle<UIButton> {
      switch self {
      case .dark:
         return Style.Button.aletrGreaterButtonDark

      case .light:
         return Style.Button.aletrGreaterButtonLight
      }
   }

   var createAlertGreaterSelectedButton: UIViewStyle<UIButton> {
      switch self {
      case .dark:
         return Style.Button.aletrGreaterButtonSelectedDark

      case .light:
         return Style.Button.aletrGreaterButtonSelectedLight
      }
   }

   var createAlertPresentr: Presentr {
      switch self {
      case .dark:
         return Presentr.createAlertPresenterDark

      case .light:
         return Presentr.createAlertPresenterLight
      }
   }

   var baseSymbolLabel: UIViewStyle<UILabel> {
      switch self {
      case .dark:
         return Style.Label.baseSymbolLabelDark

      case .light:
         return Style.Label.baseSymbolLabelLight
      }
   }

   var alertExchangeLabel: UIViewStyle<UILabel> {
      switch self {
      case .dark:
         return Style.Label.alertExchangeLabelDark

      case .light:
         return Style.Label.alertExchangeLabelDark
      }
   }

   var loadStateViewActionButton: UIViewStyle<UIButton> {
      switch self {
      case .dark:
         return Style.Button.loadStateViewActionButtonDark

      case .light:
         return Style.Button.loadStateViewActionButtonLight
      }
   }

   var loadingIndicatorOverlayView: UIViewStyle<UIView> {
      switch self {
      case .dark:
         return Style.View.whiteFourteen

      case .light:
         return Style.View.blackThirtyThree
      }
   }

   var selectExchangeLabel: UIViewStyle<UILabel> {
      switch self {
      case .dark:
         return Style.Label.selectExchangeWhiteText

      case .light:
         return Style.Label.selectExchangeBlackText
      }
   }
}

final class ThemeProvider {
   private static let theme = BehaviorRelay<Theme?>(value: nil)

   static var current: Driver<Theme> {
      return theme.asDriver().filterNil()
   }

   static func setCurrentTheme(theme: Theme) {
      UserDefaults.standard.set(theme.rawValue, forKey: Theme.identifier)
      UserDefaults.standard.synchronize()

      self.theme.accept(theme)
   }
}
