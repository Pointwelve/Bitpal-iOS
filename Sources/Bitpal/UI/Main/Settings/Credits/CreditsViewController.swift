//
//  CreditsViewController.swift
//  App
//
//  Created by James Lai on 8/11/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import RxCocoa
import RxSwift
import SafariServices
import UIKit

class CreditsViewController: UIViewController, DefaultViewControllerType, ScreenNameable {
   private enum Metric {
      static let contentTextViewTopGap: CGFloat = 14.0
      static let contentTextViewBottomGap: CGFloat = -12.0
      static let contentTextViewLeadingTrailingGap: CGFloat = 12.0
   }

   var viewModel: CreditsViewModel!

   var disposeBag = DisposeBag()

   var screenNameAccessibilityId: AccessibilityIdentifier {
      return .staticContentNavigationTitle
   }

   private lazy var contentTextView: UITextView = {
      let contentTextView = UITextView()
      contentTextView.translatesAutoresizingMaskIntoConstraints = false
      contentTextView.isUserInteractionEnabled = true
      contentTextView.delegate = self
      contentTextView.setAccessibility(id: .staticContentTextView)
      return contentTextView
   }()

   func layout() {
      update(screenName: "Credits".localized())

      [contentTextView].forEach(view.addSubview)

      NSLayoutConstraint.activate([
         contentTextView.topAnchor.constraint(equalTo: view.topAnchor,
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

      output.content
         .drive(onNext: { [weak self] content in
            self?.contentTextView.attributedText = content
         })
         .disposed(by: disposeBag)

      ThemeProvider.current
         .drive(onNext: { [weak self] theme in
            guard let `self` = self else {
               return
            }
            theme.view.apply(to: self.view)
            theme.temsAndConditionsTextView.apply(to: self.contentTextView)
         })
         .disposed(by: disposeBag)
   }
}

extension CreditsViewController: UITextViewDelegate {
   func textView(_ textView: UITextView,
                 shouldInteractWith URL: URL,
                 in characterRange: NSRange,
                 interaction: UITextItemInteraction) -> Bool {
      let safariVC = SFSafariViewController(url: URL)
      let navController = UINavigationController(rootViewController: safariVC)
      navController.isNavigationBarHidden = true
      navigationController?.present(navController, animated: true, completion: nil)
      return false
   }
}
