//
//  Style.swift
//  SEED
//
//  Created by Ryne Cheow on 25/3/17.
//  Copyright © 2017 Tigerspike. All rights reserved.
//

import UIKit

/// Style should be applied to each component in a `View`.

enum Style {
   enum LineHeight: CGFloat {
      case sample
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
   }

   enum View {
      static let white: UIViewStyle<UIView> = UIViewStyle {
         $0.backgroundColor = .white
      }
   }

   enum Button {
      private static let base: UIViewStyle<UIButton> = UIViewStyle {
         $0.titleLabel?.font = UIFont.systemFont(ofSize: 12)
      }
   }

   enum Label {
      private static let base: UIViewStyle<UILabel> = UIViewStyle {
         $0.font = UIFont.systemFont(ofSize: 12)
      }

      private static let black: UIViewStyle<UILabel> = UIViewStyle {
         $0.textColor = .black
      }

      static let blackText = UIViewStyle<UILabel>.compose(base, black)
   }

   enum Cell {
      private static let base: UIViewStyle<UITableViewCell> = UIViewStyle {
         $0.textLabel?.backgroundColor = .clear
         $0.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: -20)
      }
   }

   enum TableView {
      private enum Metric {
         static let rowHeight: CGFloat = 46
      }

      static let base: UIViewStyle<UITableView> = UIViewStyle {
         $0.bounces = false
         $0.separatorStyle = .none
         $0.rowHeight = Metric.rowHeight
      }
   }

   enum NavigationBar {
      static let white: UIViewStyle<UINavigationBar> = UIViewStyle {
         $0.barTintColor = .white
         $0.isTranslucent = false
         // This must be set otherwise the custom titleView will appear in the wrong location
         $0.setTitleVerticalPositionAdjustment(-4, for: .default)
      }

      static let noHairline: UIViewStyle<UINavigationBar> = UIViewStyle {
         $0.shadowImage = UIImage()
         $0.setBackgroundImage(UIImage(), for: .default)
      }
   }

   enum TabBar {
      case sample
      static let white: UIViewStyle<UITabBar> = UIViewStyle {
         $0.barTintColor = .white
         $0.isTranslucent = false
         $0.tintColor = .black
      }

      static func itemImage(_ value: ImageType) -> UIViewStyle<UITabBarItem> {
         return UIViewStyle<UITabBarItem> {
            $0.image = value.resource
            $0.selectedImage = value.resourceWhileSelected
            $0.imageInsets = UIEdgeInsets(top: -3, left: 0, bottom: 3, right: 0)
            $0.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -4)
         }
      }
   }

   enum StackView {
      private static let vertical: UIViewStyle<UIStackView> = UIViewStyle {
         $0.axis = .vertical
      }

      private static let centerAligned: UIViewStyle<UIStackView> = UIViewStyle {
         $0.alignment = .center
      }

      static let verticalCentered = UIViewStyle<UIStackView>.compose(vertical, centerAligned)
   }

   static func applyProxy() {
      // Apply proxies here
   }
}
