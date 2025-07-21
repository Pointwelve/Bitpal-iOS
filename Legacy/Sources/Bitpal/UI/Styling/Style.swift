//
//  Style.swift
//  App
//
//  Created by Ryne Cheow on 25/3/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import UIKit

/// Style should be applied to each component in a `View`.

// swiftlint:disable file_length type_body_length
enum Style {
   enum LineHeight {
      static let backgroundErrorMessage: CGFloat = 22.0
   }

   enum LetterSpacing: CGFloat {
      case sample
   }

   enum ImageView {
      case sample

      static func image(_ value: ImageType) -> UIViewStyle<UIImageView> {
         return UIViewStyle<UIImageView> {
            $0.image = value.resource
         }
      }

      static func tint(with color: UIColor, image: UIImage) -> UIViewStyle<UIImageView> {
         return UIViewStyle<UIImageView> {
            $0.image = image.withRenderingMode(.alwaysTemplate)
            $0.tintColor = color
         }
      }
   }

   enum View {
      static let base: UIViewStyle<UIView> = UIViewStyle {
         $0.backgroundColor = Color.dark
      }

      static let dark = base

      static let darkTwo: UIViewStyle<UIView> = UIViewStyle {
         $0.backgroundColor = Color.darkTwo
      }

      static let darkThree: UIViewStyle<UIView> = UIViewStyle {
         $0.backgroundColor = Color.darkThree
      }

      static let blackThirtyThree: UIViewStyle<UIView> = UIViewStyle {
         $0.backgroundColor = Color.blackThirtyThree
      }

      static let light: UIViewStyle<UIView> = UIViewStyle {
         $0.backgroundColor = Color.white
      }

      static let whiteThree: UIViewStyle<UIView> = UIViewStyle {
         $0.backgroundColor = Color.whiteThree
      }

      static let whiteFourteen: UIViewStyle<UIView> = UIViewStyle {
         $0.backgroundColor = Color.whiteFourteen
      }

      static func background(with color: UIColor) -> UIViewStyle<UIView> {
         return UIViewStyle<UIView> {
            $0.backgroundColor = color
         }
      }

      static let circle: UIViewStyle<UIView> = UIViewStyle {
         $0.layer.cornerRadius = $0.bounds.width / 2
      }

      static func radius(with radius: CGFloat) -> UIViewStyle<UIView> {
         return UIViewStyle<UIView> {
            $0.layer.cornerRadius = radius
         }
      }

      static let popup: UIViewStyle<UIView> = UIViewStyle {
         $0.layer.masksToBounds = false
         $0.layer.shadowColor = Color.black.cgColor
         $0.layer.shadowOpacity = 0.5
         $0.layer.shadowOffset = CGSize(width: 0, height: 3)
         $0.layer.shadowRadius = 2
      }

      static let popupDark = UIViewStyle<UIView>.compose(popup, darkThree)

      static let popupLight = UIViewStyle<UIView>.compose(popup, light)

      static let popupBackgroundDark: UIViewStyle<UIVisualEffectView> = UIViewStyle {
         $0.effect = UIBlurEffect(style: .dark)
      }

      static let popupBackgroundLight: UIViewStyle<UIVisualEffectView> = UIViewStyle {
         $0.effect = UIBlurEffect(style: .light)
      }
   }

   enum Button {
      private static let base: UIViewStyle<UIButton> = UIViewStyle {
         $0.titleLabel?.font = UIFont.systemFont(ofSize: 12)
      }

      private static let semiBold16: UIViewStyle<UIButton> = UIViewStyle {
         $0.titleLabel?.font = Font.semiBold16
      }

      private static let darkFive: UIViewStyle<UIButton> = UIViewStyle {
         $0.setTitleColor(Color.darkThree, for: .normal)
      }

      private static let titleDarkFive: UIViewStyle<UIButton> = UIViewStyle {
         $0.setTitleColor(Color.darkFive, for: .normal)
      }

      private static let titleWarmGrey: UIViewStyle<UIButton> = UIViewStyle {
         $0.setTitleColor(Color.warmGrey, for: .normal)
      }

      private static let titleGreyishFour: UIViewStyle<UIButton> = UIViewStyle {
         $0.setTitleColor(Color.greyishFour, for: .normal)
      }

      private static let white: UIViewStyle<UIButton> = UIViewStyle {
         $0.setTitleColor(Color.white, for: .normal)
      }

      private static let backgroundDarkThree: UIViewStyle<UIButton> = UIViewStyle {
         $0.backgroundColor = Color.darkThree
      }

      private static let backgroundWhite: UIViewStyle<UIButton> = UIViewStyle {
         $0.backgroundColor = Color.white
      }

      private static let backgroundTealish: UIViewStyle<UIButton> = UIViewStyle {
         $0.backgroundColor = Color.tealish
      }

      private static let rounded16: UIViewStyle<UIButton> = UIViewStyle {
         $0.layer.cornerRadius = 16
      }

      static let popupDefault: UIViewStyle<UIButton> = UIViewStyle {
         $0.titleLabel?.font = Font.regular12
         $0.backgroundColor = Color.tealish
      }

      static let popupDefaultDark = UIViewStyle<UIButton>.compose(popupDefault, titleDarkFive)
      static let popupDefaultLight = UIViewStyle<UIButton>.compose(popupDefault, white)

      static let popupCancel: UIViewStyle<UIButton> = UIViewStyle {
         $0.titleLabel?.font = Font.regular12
      }

      static let popupCancelDark: UIViewStyle<UIButton> =
         UIViewStyle<UIButton>.compose(popupCancel, titleWarmGrey, backgroundDarkThree)
      static let popupCancelLight: UIViewStyle<UIButton> =
         UIViewStyle<UIButton>.compose(popupCancel, titleGreyishFour, backgroundWhite)

      static let createAlertDark = UIViewStyle<UIButton>.compose(rounded16, semiBold16, darkFive, backgroundTealish)
      static let createAlertLight = UIViewStyle<UIButton>.compose(rounded16, semiBold16, white, backgroundTealish)

      static let aletrGreaterButtonDark: UIViewStyle<UIButton> = UIViewStyle {
         $0.titleLabel?.font = Font.light25
         $0.backgroundColor = UIColor.clear
         $0.layer.cornerRadius = 45.0 / 2.0
         $0.layer.borderColor = Color.brownishGrey.cgColor
         $0.layer.borderWidth = 1.0
         $0.setTitleColor(Color.warmGreySix, for: .normal)
      }

      static let aletrGreaterButtonLight: UIViewStyle<UIButton> = UIViewStyle {
         $0.titleLabel?.font = Font.light25
         $0.backgroundColor = UIColor.clear
         $0.layer.cornerRadius = 45.0 / 2.0
         $0.layer.borderColor = Color.whiteSeven.cgColor
         $0.layer.borderWidth = 1.0
         $0.setTitleColor(Color.greyishFour, for: .normal)
      }

      static let aletrGreaterButtonSelectedDark: UIViewStyle<UIButton> = UIViewStyle {
         $0.titleLabel?.font = Font.bold25
         $0.backgroundColor = Color.tealish
         $0.layer.cornerRadius = 45.0 / 2.0
         $0.layer.borderColor = Color.tealish.cgColor
         $0.layer.borderWidth = 1.0
         $0.setTitleColor(Color.darkThree, for: .normal)
      }

      static let aletrGreaterButtonSelectedLight: UIViewStyle<UIButton> = UIViewStyle {
         $0.titleLabel?.font = Font.bold25
         $0.backgroundColor = Color.tealish
         $0.layer.cornerRadius = 45.0 / 2.0
         $0.layer.borderColor = Color.tealish.cgColor
         $0.layer.borderWidth = 1.0
         $0.setTitleColor(Color.white, for: .normal)
      }

      static let loadStateViewActionButtonDark: UIViewStyle<UIButton> = UIViewStyle {
         $0.contentEdgeInsets = UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16)
         $0.titleLabel?.font = Font.bold12
         $0.tintColor = Color.greyish
         $0.layer.borderWidth = 1.5
         $0.layer.borderColor = Color.warmGreyLight.cgColor
         $0.layer.cornerRadius = 8.0
      }

      static let loadStateViewActionButtonLight: UIViewStyle<UIButton> = UIViewStyle {
         $0.contentEdgeInsets = UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16)
         $0.titleLabel?.font = Font.bold12
         $0.tintColor = Color.warmGreyLight
         $0.layer.borderWidth = 1.5
         $0.layer.borderColor = Color.greyish.cgColor
         $0.layer.cornerRadius = 8.0
      }
   }

   enum Label {
      private static let base: UIViewStyle<UILabel> = UIViewStyle {
         $0.font = Font.regular12
      }

      private static let bold14: UIViewStyle<UILabel> = UIViewStyle {
         $0.font = Font.bold14
      }

      private static let bold18: UIViewStyle<UILabel> = UIViewStyle {
         $0.font = Font.bold18
      }

      private static let semiBold14: UIViewStyle<UILabel> = UIViewStyle {
         $0.font = Font.semiBold14
      }

      private static let semiBold15: UIViewStyle<UILabel> = UIViewStyle {
         $0.font = Font.semiBold15
      }

      private static let semiBold16: UIViewStyle<UILabel> = UIViewStyle {
         $0.font = Font.semiBold16
      }

      private static let semiBold18: UIViewStyle<UILabel> = UIViewStyle {
         $0.font = Font.semiBold18
      }

      private static let regular18: UIViewStyle<UILabel> = UIViewStyle {
         $0.font = Font.regular18
      }

      private static let regular14: UIViewStyle<UILabel> = UIViewStyle {
         $0.font = Font.regular14
      }

      private static let regular15: UIViewStyle<UILabel> = UIViewStyle {
         $0.font = Font.regular15
      }

      private static let regular16: UIViewStyle<UILabel> = UIViewStyle {
         $0.font = Font.regular16
      }

      private static let light14: UIViewStyle<UILabel> = UIViewStyle {
         $0.font = Font.light14
      }

      private static let light36: UIViewStyle<UILabel> = UIViewStyle {
         $0.font = Font.light36
      }

      private static let black: UIViewStyle<UILabel> = UIViewStyle {
         $0.textColor = .black
      }

      private static let dark: UIViewStyle<UILabel> = UIViewStyle {
         $0.textColor = Color.dark
      }

      private static let white: UIViewStyle<UILabel> = UIViewStyle {
         $0.textColor = .white
      }

      private static let whiteSeven: UIViewStyle<UILabel> = UIViewStyle {
         $0.textColor = Color.whiteSeven
      }

      private static let whiteFour: UIViewStyle<UILabel> = UIViewStyle {
         $0.textColor = Color.whiteFour
      }

      private static let pinkishGreyThree: UIViewStyle<UILabel> = UIViewStyle {
         $0.textColor = Color.pinkishGreyThree
      }

      private static let darkTwo: UIViewStyle<UILabel> = UIViewStyle {
         $0.textColor = Color.darkTwo
      }

      private static let darkThree: UIViewStyle<UILabel> = UIViewStyle {
         $0.textColor = Color.darkThree
      }

      private static let darkFour: UIViewStyle<UILabel> = UIViewStyle {
         $0.textColor = Color.darkFour
      }

      private static let warmGrey: UIViewStyle<UILabel> = UIViewStyle {
         $0.textColor = Color.warmGrey
      }

      private static let warmGreyLight: UIViewStyle<UILabel> = UIViewStyle {
         $0.textColor = Color.warmGreyLight
      }

      private static let warmGreySeven: UIViewStyle<UILabel> = UIViewStyle {
         $0.textColor = Color.warmGreySeven
      }

      private static let purpleGrey: UIViewStyle<UILabel> = UIViewStyle {
         $0.textColor = Color.purpleyGrey
      }

      private static let greyishTwo = UIViewStyle<UILabel> {
         $0.textColor = Color.greyishTwo
      }

      private static let greyishBrownTwo = UIViewStyle<UILabel> {
         $0.textColor = Color.greyishBrownTwo
      }

      private static let backgroundErrorTitle = UIViewStyle<UILabel> {
         $0.font = Font.light36
         $0.numberOfLines = 0
      }

      private static let backgroundErrorMessage = UIViewStyle<UILabel> {
         $0.font = Font.light14
         $0.numberOfLines = 0
      }

      private static let settingsVersionLabel = UIViewStyle<UILabel> {
         $0.font = Font.light14
         $0.textAlignment = .center
      }

      private static let darkThree66: UIViewStyle<UILabel> = UIViewStyle {
         $0.textColor = Color.darkThree66
      }

      private static let warmGreyFive: UIViewStyle<UILabel> = UIViewStyle {
         $0.textColor = Color.warmGreyFive
      }

      private static let center: UIViewStyle<UILabel> = UIViewStyle {
         $0.textAlignment = .center
      }

      private static let numberOfLines2: UIViewStyle<UILabel> = UIViewStyle {
         $0.numberOfLines = 2
      }

      static let blackText = UIViewStyle<UILabel>.compose(base, black)

      static let priceListWhiteText = UIViewStyle<UILabel>.compose(white, bold18)

      static let priceListBlackText = UIViewStyle<UILabel>.compose(black, bold18)

      static let priceListDarkThreeText = UIViewStyle<UILabel>.compose(darkThree, regular18)

      static let priceListGrayText = UIViewStyle<UILabel>.compose(warmGrey, regular18)

      static let priceListBaseCurrencyWhiteText = UIViewStyle<UILabel>.compose(white, semiBold18)

      static let priceListBaseCurrencyBlackText = UIViewStyle<UILabel>.compose(black, semiBold18)

      static let priceListPriceWhiteText = UIViewStyle<UILabel>.compose(white, semiBold18)

      static let priceListPriceDarkThreeText = UIViewStyle<UILabel>.compose(darkThree, semiBold18)

      static let darkPriceListExchangeText = UIViewStyle<UILabel>.compose(purpleGrey, regular14)

      static let lightPriceListExchangeText = UIViewStyle<UILabel>.compose(darkTwo, regular14)

      static let selectExchangeWhiteText = UIViewStyle<UILabel>.compose(white, regular18)

      static let selectExchangeBlackText = UIViewStyle<UILabel>.compose(black, regular18)

      static let darkBackgorundErrorTitle = UIViewStyle<UILabel>.compose(backgroundErrorTitle, warmGrey)

      static let lightBackgorundErrorTitle = UIViewStyle<UILabel>.compose(backgroundErrorTitle, darkFour)

      static let darkBackgroundErrorMessage = UIViewStyle<UILabel>.compose(backgroundErrorMessage, warmGreyLight)

      static let lightBackgroundErrorMessage = UIViewStyle<UILabel>.compose(backgroundErrorMessage, darkFour)

      static let darkSettingsVersionLabel = UIViewStyle<UILabel>.compose(settingsVersionLabel, purpleGrey)

      static let lightSettingsVersionLabel = UIViewStyle<UILabel>.compose(settingsVersionLabel, black)

      static let headerBaseSymbolGreyText = UIViewStyle<UILabel>.compose(purpleGrey, bold14)

      static let headerBaseFullnameWhiteText = UIViewStyle<UILabel>.compose(white, regular14)

      static let headerBaseFullnameBlackText = UIViewStyle<UILabel>.compose(black, regular14)

      static let darkSettingsTitleLabel = UIViewStyle<UILabel> {
         $0.font = Font.regular14
         $0.textColor = Color.white
      }

      static let lightSettingsTitleLabel = UIViewStyle<UILabel> {
         $0.font = Font.regular14
         $0.textColor = Color.darkThree
      }

      static let settingsDescriptionLabel = UIViewStyle<UILabel> {
         $0.font = Font.regular16
         $0.textColor = Color.purpleyGrey
      }

      static let darkTermsCompanyTitleLabel = UIViewStyle.compose(regular18, greyishTwo)

      static let lightTermsCompanyTitleLabel = UIViewStyle.compose(regular18, greyishBrownTwo)

      static let priceListExchangeLabel = UIViewStyle<UILabel>.compose(purpleGrey, regular14)

      static let pricePercentageLabel = UIViewStyle<UILabel> {
         $0.font = Font.regular10
         $0.textColor = Color.white
         $0.textAlignment = .center
      }

      // Price Detail

      // Dark
      static let priceDetailDarkLabel = UIViewStyle.compose(whiteSeven, light36)
      static let priceDetailDarkPctLabel = UIViewStyle.compose(pinkishGreyThree)
      static let priceDetailDarkDayLabel = UIViewStyle.compose(pinkishGreyThree, base)

      static let priceDetailDarkStatisticDetailLabel = UIViewStyle.compose(whiteFour, regular16)

      // Light
      static let priceDetailLightLabel = UIViewStyle.compose(darkThree, light36)
      static let priceDetailLightPctLabel = UIViewStyle.compose(dark)
      static let priceDetailLightDayLabel = UIViewStyle.compose(dark, base)

      static let priceDetailLightStatisticDetailLabel = UIViewStyle.compose(darkThree, regular16)

      static let priceDetailBasePctLabel = UIViewStyle<UILabel>.compose(regular14, white)

      static let popupTitle = UIViewStyle<UILabel> {
         $0.font = Font.regular20
         $0.textAlignment = .center
         $0.numberOfLines = 0
      }

      static let popupTitleDark = UIViewStyle<UILabel>.compose(white, popupTitle)
      static let popupTitleLight = UIViewStyle<UILabel>.compose(darkThree, popupTitle)

      static let popupMessage = UIViewStyle<UILabel> {
         $0.font = Font.regular14
         $0.textAlignment = .center
         $0.numberOfLines = 0
      }

      static let popupMessageDark = UIViewStyle<UILabel>.compose(white, popupMessage)
      static let popupMessageLight = UIViewStyle<UILabel>.compose(darkThree, popupMessage)

      static let priceAlertSymbolDark = UIViewStyle<UILabel>.compose(whiteSeven, light36)
      static let priceAlertSymbolLight = UIViewStyle<UILabel>.compose(darkThree, light36)

      static let alertMessage = UIViewStyle<UILabel>.compose(warmGreyFive, light14, center, numberOfLines2)

      static let baseSymbolLabelDark = UIViewStyle<UILabel>.compose(semiBold18, white)
      static let baseSymbolLabelLight = UIViewStyle<UILabel>.compose(semiBold18, darkThree)

      static let quoteSymbolLabel = UIViewStyle<UILabel>.compose(regular15, purpleGrey)

      static let alertPriceLabel = UIViewStyle<UILabel>.compose(semiBold14, warmGreySeven, center)

      static let alertExchangeLabelDark = UIViewStyle<UILabel>.compose(regular14, warmGreySeven)
      static let alertExchangeLabelLight = UIViewStyle<UILabel>.compose(regular14, purpleGrey)
   }

   enum TextField {
      static let darkSearch = UIViewStyle<UITextField> {
         $0.font = Font.regular16
         $0.textColor = Color.white
         $0.keyboardAppearance = .dark
      }

      static let lightSearch = UIViewStyle<UITextField> {
         $0.font = Font.regular16
         $0.textColor = Color.dark
         $0.keyboardAppearance = .light
      }

      static let alertPriceDark = UIViewStyle<UITextField> {
         $0.font = Font.light36
         $0.textColor = Color.whiteSeven
         $0.keyboardAppearance = .dark
         $0.keyboardType = .decimalPad
      }

      static let alertPriceLight = UIViewStyle<UITextField> {
         $0.font = Font.light36
         $0.textColor = Color.darkThree
         $0.keyboardAppearance = .light
         $0.keyboardType = .decimalPad
      }
   }

   enum TextView {
      private static let termsAndCondition = UIViewStyle<UITextView> {
         $0.isEditable = false
         $0.font = Font.regular12
         $0.textColor = Color.warmGreyTwo
         $0.backgroundColor = .clear
      }

      private static let darkIndicatorStyle = UIViewStyle<UITextView> {
         $0.indicatorStyle = .white
      }

      private static let lightIndicatorStyle = UIViewStyle<UITextView> {
         $0.indicatorStyle = .black
      }

      static let darkTermsAndCondition = UIViewStyle<UITextView>.compose(termsAndCondition, darkIndicatorStyle)

      static let lightTermsAndCondition = UIViewStyle<UITextView>.compose(termsAndCondition, lightIndicatorStyle)
   }

   enum Cell {
      private static let base: UIViewStyle<UITableViewCell> = UIViewStyle {
         $0.textLabel?.backgroundColor = .clear
         $0.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: -20)
      }

      static let dark: UIViewStyle<UITableViewCell> = UIViewStyle {
         $0.backgroundColor = Color.dark
      }

      static let darkThree: UIViewStyle<UITableViewCell> = UIViewStyle {
         $0.backgroundColor = Color.darkThree
      }

      static let light: UIViewStyle<UITableViewCell> = UIViewStyle {
         $0.backgroundColor = .white
      }

      static let lightTwo: UIViewStyle<UITableViewCell> = UIViewStyle {
         $0.backgroundColor = Color.whiteTwo
      }
   }

   enum TableView {
      private enum Metric {
         static let rowHeight: CGFloat = 46
      }

      private static let base: UIViewStyle<UITableView> = UIViewStyle {
         $0.separatorStyle = .none
      }

      private static let darkBg: UIViewStyle<UITableView> = UIViewStyle {
         $0.backgroundColor = Color.dark
         $0.indicatorStyle = .white
      }

      private static let lightBg: UIViewStyle<UITableView> = UIViewStyle {
         $0.backgroundColor = UIColor.white
         $0.indicatorStyle = .black
      }

      static let main = UIViewStyle<UITableView>.compose(base, darkBg)

      static let dark = UIViewStyle<UITableView>.compose(base, darkBg)

      static let light = UIViewStyle<UITableView>.compose(base, lightBg)
   }

   enum NavigationBar {
      private static let base: UIViewStyle<UINavigationBar> = UIViewStyle {
         $0.isTranslucent = false
         // This must be set otherwise the custom titleView will appear in the wrong location
         $0.titleTextAttributes = [.font: Font.semiBold16]
         $0.tintColor = Color.tealish
         if #available(iOS 11.0, *) {
            $0.largeTitleTextAttributes = [.font: Font.regular34]
         }
      }

      private static let white: UIViewStyle<UINavigationBar> = UIViewStyle {
         $0.barTintColor = Color.white
      }

      private static let whiteText: UIViewStyle<UINavigationBar> = UIViewStyle {
         guard var attributes = $0.titleTextAttributes else { return }
         attributes[.foregroundColor] = Color.white
         $0.titleTextAttributes = attributes
      }

      private static let whiteLargeTitleText: UIViewStyle<UINavigationBar> = UIViewStyle {
         guard #available(iOS 11.0, *), var attributes = $0.largeTitleTextAttributes else { return }
         attributes[.foregroundColor] = Color.white
         $0.largeTitleTextAttributes = attributes
      }

      private static let blackLargeTitleText: UIViewStyle<UINavigationBar> = UIViewStyle {
         guard #available(iOS 11.0, *), var attributes = $0.largeTitleTextAttributes else { return }
         attributes[.foregroundColor] = Color.black
         $0.largeTitleTextAttributes = attributes
      }

      private static let black: UIViewStyle<UINavigationBar> = UIViewStyle {
         $0.barTintColor = Color.dark
      }

      private static let blackText: UIViewStyle<UINavigationBar> = UIViewStyle {
         guard var attributes = $0.titleTextAttributes else { return }
         attributes[.foregroundColor] = UIColor.black
         $0.titleTextAttributes = attributes
      }

      static let noHairline: UIViewStyle<UINavigationBar> = UIViewStyle {
         $0.shadowImage = UIImage()
         $0.setBackgroundImage(UIImage(), for: .default)
      }

      static let dark: UIViewStyle<UINavigationBar> = UIViewStyle.compose(base, black, whiteText, whiteLargeTitleText)

      static let light: UIViewStyle<UINavigationBar> = UIViewStyle.compose(base, white, blackText, blackLargeTitleText)

      fileprivate static func applyBackButtonStyle() {
         let backImage = Image.backIcon.resource
         let appearance = UINavigationBar.appearance()
         appearance.backIndicatorImage = backImage
         appearance.backIndicatorTransitionMaskImage = backImage
      }
   }

   enum TabBar {
      static let dark: UIViewStyle<UITabBar> = UIViewStyle {
         $0.barTintColor = Color.dark78
         $0.isTranslucent = false
         $0.tintColor = Color.tealish
         $0.unselectedItemTintColor = Color.warmGrey
      }

      static let light: UIViewStyle<UITabBar> = UIViewStyle {
         $0.barTintColor = .white
         $0.isTranslucent = false
         $0.tintColor = Color.tealish
         $0.unselectedItemTintColor = Color.warmGrey
      }

      static func itemImage(_ value: ImageType) -> UIViewStyle<UITabBarItem> {
         return UIViewStyle<UITabBarItem> {
            $0.image = value.resource
            $0.selectedImage = value.resourceWhileSelected
            $0.imageInsets = UIEdgeInsets(top: -3, left: 0, bottom: 3, right: 0)
            $0.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -4)
         }
      }

      fileprivate static func applyTabStyle() {
         let appearance = UITabBarItem.appearance()
         appearance.setTitleTextAttributes([
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: Color.warmGrey
         ],
                                           for: .normal)
         appearance.setTitleTextAttributes([
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: Color.tealish
         ],
                                           for: .selected)
      }
   }

   enum StackView {
      static let vertical: UIViewStyle<UIStackView> = UIViewStyle {
         $0.axis = .vertical
      }

      private static let horizontal: UIViewStyle<UIStackView> = UIViewStyle {
         $0.axis = .horizontal
      }

      private static let centerAligned: UIViewStyle<UIStackView> = UIViewStyle {
         $0.alignment = .center
      }

      private static let gap5: UIViewStyle<UIStackView> = UIViewStyle {
         $0.spacing = 5.0
      }

      static let verticalCentered = UIViewStyle<UIStackView>.compose(vertical, centerAligned)

      static let watchlistDetailPriceStackView = UIViewStyle<UIStackView>
         .compose(horizontal, gap5)
   }

   enum AttributedString {
      static func watchlistDetailTitleFirstLine(_ string: String, color: UIColor) -> NSAttributedString {
         return string.attributedString(textAlignment: .center,
                                        textColor: color,
                                        font: Font.regular14)
      }

      static func watchlistDetailTitleSecondLine(_ string: String, color: UIColor) -> NSAttributedString {
         return string.attributedString(textAlignment: .center,
                                        textColor: color,
                                        font: Font.regular11)
      }

      static func chartPeriodText(_ string: String, color: UIColor = Color.white) -> NSAttributedString {
         return string.attributedString(withLetterSpacing: 0.2,
                                        textAlignment: .center,
                                        textColor: color,
                                        font: Font.regular12)
      }

      static func watchDetailDateText(_ string: String) -> NSAttributedString {
         return string.attributedString(withLetterSpacing: 0.2,
                                        textAlignment: .center,
                                        textColor: Color.warmGreyFour,
                                        font: Font.regular12)
      }
   }

   static func applyProxy() {
      // Apply proxies here
      NavigationBar.applyBackButtonStyle()
      TabBar.applyTabStyle()
   }
}
