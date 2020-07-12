//
//  SplashViewController.swift
//  App
//
//  Created by Li Hao Lai on 26/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import NVActivityIndicatorView
import RxCocoa
import RxSwift
import UIKit

class SplashViewController: UIViewController, DefaultViewControllerType {
   private enum Metrics {
      static let logoWidth: CGFloat = 108
      static let logoHeight: CGFloat = 109
   }

   typealias ViewModel = SplashViewModel

   var disposeBag = DisposeBag()
   var viewModel: SplashViewModel!

   private lazy var logoImageView: UIImageView = {
      let imageView = UIImageView(image: Image.appLogo.resource)
      imageView.translatesAutoresizingMaskIntoConstraints = false

      return imageView
   }()

   private lazy var migrationPopupView: PopupView = {
      let popup = PopupView()
      popup.translatesAutoresizingMaskIntoConstraints = false
      popup.isHidden = true
      popup.layout()

      return popup
   }()

   private lazy var activityIndicatorView: NVActivityIndicatorView = {
      let activityIndicatorView = NVActivityIndicatorView(frame: .init(x: 0,
                                                                       y: 0,
                                                                       width: 30,
                                                                       height: 20),
                                                          type: .lineScale,
                                                          color: Color.coolGreyTwo,
                                                          padding: 0)
      activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
      activityIndicatorView.startAnimating()
      return activityIndicatorView
   }()

   func layout() {
      [logoImageView, activityIndicatorView, migrationPopupView].forEach(view.addSubview)

      NSLayoutConstraint.activate([
         logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
         logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
         logoImageView.widthAnchor.constraint(equalToConstant: Metrics.logoWidth),
         logoImageView.heightAnchor.constraint(equalToConstant: Metrics.logoHeight),

         activityIndicatorView.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 20),
         activityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
         activityIndicatorView.widthAnchor.constraint(equalToConstant: 30),
         activityIndicatorView.heightAnchor.constraint(equalToConstant: 20),

         migrationPopupView.topAnchor.constraint(equalTo: view.topAnchor),
         migrationPopupView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
         migrationPopupView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
         migrationPopupView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
      ])
   }

   func bind() {
      let output = viewModel
         .transform(input: .init(migrationSkipAction: migrationPopupView.cancelButtonTappedDriver,
                                 migrationProceedAction: migrationPopupView.defaultButtonTappedDriver))
      migrationPopupView.bind(data: .migration)
      output.peekDeviceFingerprint
         .drive()
         .disposed(by: disposeBag)

      output.promptOverrideMigration.not()
         .drive(migrationPopupView.rx.isHidden)
         .disposed(by: disposeBag)

      output.authenticationSuccessful
         .drive()
         .disposed(by: disposeBag)

      output.tokenDriver
         .drive()
         .disposed(by: disposeBag)

      ThemeProvider.current
         .drive(onNext: { [weak self] theme in
            guard let `self` = self else {
               return
            }
            theme.view.apply(to: self.view)
         })
         .disposed(by: disposeBag)
   }
}
