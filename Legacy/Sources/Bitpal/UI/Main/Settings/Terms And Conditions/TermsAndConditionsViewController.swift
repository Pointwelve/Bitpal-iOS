//
//  TermsAndConditionsViewController.swift
//  App
//
//  Created by James Lai on 27/7/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import RxCocoa
import RxSwift
import UIKit

class TermsAndConditionsViewController: UIViewController, DefaultViewControllerType, ScreenNameable {
   private enum Metric {
      static let companyNameLabelTopGap: CGFloat = 14.0
      static let companyNameLabelLeadingTrailingGap: CGFloat = 16.0

      static let contentTextViewTopGap: CGFloat = 14.0
      static let contentTextViewBottomGap: CGFloat = -12.0
      static let contentTextViewLeadingTrailingGap: CGFloat = 12.0
   }

   typealias ViewModel = TermsAndConditionsViewModel

   var viewModel: TermsAndConditionsViewModel!

   var disposeBag = DisposeBag()

   private lazy var companyTitleLabel: UILabel = {
      let companyTitleLabel = UILabel()
      companyTitleLabel.translatesAutoresizingMaskIntoConstraints = false
      companyTitleLabel.setAccessibility(id: .staticContentCompanyTitleLabel)

      return companyTitleLabel
   }()

   private lazy var contentTextView: UITextView = {
      let contentTextView = UITextView()
      contentTextView.translatesAutoresizingMaskIntoConstraints = false
      contentTextView.setAccessibility(id: .staticContentTextView)
      return contentTextView
   }()

   var screenNameAccessibilityId: AccessibilityIdentifier {
      return .staticContentNavigationTitle
   }

   func layout() {
      update(screenName: "settings.termsAndPrivacy.title".localized())

      [companyTitleLabel, contentTextView].forEach(view.addSubview)

      NSLayoutConstraint.activate([
         companyTitleLabel.topAnchor.constraint(equalTo: view.topAnchor,
                                                constant: Metric.companyNameLabelTopGap),
         companyTitleLabel.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor,
                                                    constant: Metric.companyNameLabelLeadingTrailingGap),
         companyTitleLabel.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor,
                                                     constant: Metric.companyNameLabelLeadingTrailingGap),

         contentTextView.topAnchor.constraint(equalTo: companyTitleLabel.bottomAnchor,
                                              constant: Metric.contentTextViewTopGap),
         contentTextView.bottomAnchor.constraint(equalTo: view.bottomAnchor,
                                                 constant: Metric.contentTextViewBottomGap),
         contentTextView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor,
                                                  constant: Metric.contentTextViewLeadingTrailingGap),
         contentTextView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor,
                                                   constant: -Metric.contentTextViewLeadingTrailingGap)
      ])

      if #available(iOS 11.0, *) {
         navigationItem.largeTitleDisplayMode = .never
      }
   }

   func bind() {
      let output = viewModel.transform(input: ())

      output.companyTitleDriver
         .drive(companyTitleLabel.rx.text)
         .disposed(by: disposeBag)

      output.termsAndConditionsDriver
         .drive(onNext: { [weak self] termsAndConditions in
            let unescapeTC = termsAndConditions.replacingOccurrences(of: "\\n", with: "\n")
            self?.contentTextView.text = unescapeTC
         })
         .disposed(by: disposeBag)

      ThemeProvider.current
         .drive(onNext: { [weak self] theme in
            guard let `self` = self else {
               return
            }
            theme.view.apply(to: self.view)
            theme.termsCompanyTitleLabel.apply(to: self.companyTitleLabel)
            theme.temsAndConditionsTextView.apply(to: self.contentTextView)
         })
         .disposed(by: disposeBag)
   }
}
