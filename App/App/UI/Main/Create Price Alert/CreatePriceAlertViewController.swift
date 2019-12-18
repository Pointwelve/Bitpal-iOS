//
//  CreatePriceAlertViewController.swift
//  App
//
//  Created by James Lai on 5/10/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import RxCocoa
import RxSwift
import UIKit

class CreatePriceAlertViewController: UIViewController, DefaultViewControllerType {
   private enum Metrics {
      static let baseLeading: CGFloat = 8.0
      static let baseTrailing: CGFloat = -8.0
      static let contenViewHeight: CGFloat = 223.0
      static let closeButtonWidth: CGFloat = 17.0
      static let closeButtonTop: CGFloat = 16.0
      static let closeButtonTrailing: CGFloat = -12.0
      static let createButtonTopPadding: CGFloat = 25
      static let createButtonBottomPadding: CGFloat = 17
      static let greaterAndLesserContainerTop: CGFloat = 20.0
      static let greaterButtonWidth: CGFloat = 45.0
      static let alertPriceContainerTop: CGFloat = 9.0
      static let alertPriceContainerHeight: CGFloat = 49.0
      static let alertMessageTop: CGFloat = 4.0

      static let createButtonWidth: CGFloat = Reference.createButtonWidthRatio * UIScreen.main.bounds.width

      enum Reference {
         static let createButtonWidthRatio: CGFloat = 193 / 375
         static let createButtonWidthHeightRatio: CGFloat = 193 / 45
      }
   }

   typealias ViewModel = CreatePriceAlertViewModel

   var viewModel: CreatePriceAlertViewModel!
   var disposeBag = DisposeBag()

   private var contentView: UIView = {
      let view = UIView()
      view.translatesAutoresizingMaskIntoConstraints = false

      return view
   }()

   private var closeButton: UIButton = {
      let button = UIButton(type: .system)
      button.translatesAutoresizingMaskIntoConstraints = false
      button.setImage(Image.closeIcon.resource, for: .normal)
      button.tintColor = Color.tealish

      return button
   }()

   private var greaterAndLesserContainerView: UIStackView = {
      let stackView = UIStackView()
      stackView.translatesAutoresizingMaskIntoConstraints = false
      stackView.spacing = 24.0

      return stackView
   }()

   private var lesserButton: UIButton = {
      let button = UIButton(type: .custom)
      button.translatesAutoresizingMaskIntoConstraints = false
      button.isSelected = true
      button.setTitle("priceAlert.button.lessThanOrEqual".localized(), for: .normal)

      return button
   }()

   private var greaterButton: UIButton = {
      let button = UIButton(type: .custom)
      button.translatesAutoresizingMaskIntoConstraints = false
      button.setTitle("priceAlert.button.greaterThanOrEqual".localized(), for: .normal)

      return button
   }()

   private var alertPriceSymbolLabel: UILabel = {
      let label = UILabel()
      label.translatesAutoresizingMaskIntoConstraints = false

      return label
   }()

   private var alertPriceTextField: UITextField = {
      let textfield = UITextField()
      textfield.translatesAutoresizingMaskIntoConstraints = false

      return textfield
   }()

   private var alertPriceContainerView: UIStackView = {
      let stackView = UIStackView()
      stackView.translatesAutoresizingMaskIntoConstraints = false

      return stackView
   }()

   private var alertMessageLabel: UILabel = {
      let label = UILabel()
      label.translatesAutoresizingMaskIntoConstraints = false
      Style.Label.alertMessage.apply(to: label)

      return label
   }()

   private var createButton: UIButton = {
      let button = UIButton(type: .system)
      button.translatesAutoresizingMaskIntoConstraints = false
      button.setTitle("priceAlert.button.create".localized(), for: .normal)
      return button
   }()

   private var loadingIndicator: LoadingIndicator = {
      let view = LoadingIndicator()
      view.translatesAutoresizingMaskIntoConstraints = false
      view.isHidden = true

      return view
   }()

   private var validPrice = BehaviorRelay<String?>(value: nil)
   private var isLesserButtonSelected = BehaviorRelay<Bool>(value: true)

   private var bottomConstraint: NSLayoutConstraint!

   func layout() {
      [contentView].forEach(view.addSubview)
      [closeButton, createButton, greaterAndLesserContainerView, alertPriceContainerView, alertMessageLabel]
         .forEach(contentView.addSubview)
      [lesserButton, greaterButton].forEach(greaterAndLesserContainerView.addArrangedSubview)
      [alertPriceSymbolLabel, alertPriceTextField].forEach(alertPriceContainerView.addArrangedSubview)

      bottomConstraint = contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor)

      NSLayoutConstraint.activate([
         contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
         contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
         bottomConstraint,

         closeButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Metrics.closeButtonTop),
         closeButton.widthAnchor.constraint(equalToConstant: Metrics.closeButtonWidth),
         closeButton.heightAnchor.constraint(equalToConstant: Metrics.closeButtonWidth),

         greaterAndLesserContainerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
         greaterAndLesserContainerView.topAnchor.constraint(equalTo: contentView.topAnchor,
                                                            constant: Metrics.greaterAndLesserContainerTop),

         greaterButton.widthAnchor.constraint(equalToConstant: Metrics.greaterButtonWidth),
         greaterButton.heightAnchor.constraint(equalToConstant: Metrics.greaterButtonWidth),
         lesserButton.widthAnchor.constraint(equalToConstant: Metrics.greaterButtonWidth),
         lesserButton.heightAnchor.constraint(equalToConstant: Metrics.greaterButtonWidth),

         alertPriceContainerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
         alertPriceContainerView.topAnchor.constraint(equalTo: greaterAndLesserContainerView.bottomAnchor,
                                                      constant: Metrics.alertPriceContainerTop),
         alertPriceContainerView.widthAnchor
            .constraint(lessThanOrEqualToConstant: view.frame.width - Metrics.baseLeading + Metrics.baseTrailing),

         alertMessageLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
         alertMessageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Metrics.baseLeading),
         alertMessageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                     constant: Metrics.baseTrailing),
         alertMessageLabel.topAnchor.constraint(equalTo: alertPriceContainerView.bottomAnchor,
                                                constant: Metrics.alertMessageTop),

         createButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
         createButton.topAnchor.constraint(lessThanOrEqualTo: alertMessageLabel.bottomAnchor,
                                           constant: Metrics.createButtonTopPadding),
         createButton.bottomAnchor.constraint(equalTo: contentView.safeBottomAnchor,
                                              constant: -Metrics.createButtonBottomPadding),
         createButton.widthAnchor.constraint(equalTo: contentView.widthAnchor,
                                             multiplier: Metrics.Reference.createButtonWidthRatio)
      ])

      if #available(iOS 11, *) {} else {
         NSLayoutConstraint.activate([
            contentView.heightAnchor.constraint(equalToConstant: Metrics.contenViewHeight),

            closeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                  constant: Metrics.closeButtonTrailing)
         ])
      }
   }

   override func viewSafeAreaInsetsDidChange() {
      if #available(iOS 11, *) {
         super.viewSafeAreaInsetsDidChange()

         let safeAreaGuide = contentView.safeAreaLayoutGuide

         NSLayoutConstraint.activate([
            contentView.heightAnchor.constraint(equalToConstant: Metrics.contenViewHeight + view.safeAreaInsets.bottom),

            closeButton.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor,
                                                  constant: Metrics.closeButtonTrailing)
         ])
      }
   }

   func bind() {
      // Dismiss keyboard before operation
      let createTap = view.rx.tapGesture().asDriver().void()
         .do(onNext: { [weak self] in
            self?.alertPriceTextField.resignFirstResponder()
         })

      let output = viewModel.transform(input: .init(isLesserButtonSelected: isLesserButtonSelected.asDriver(),
                                                    didTapCloseButton: closeButton.rx.tap.asDriver(),
                                                    didSelectLesserButton: lesserButton.rx.tap.asDriver(),
                                                    didSelectGreaterButton: greaterButton.rx.tap.asDriver(),
                                                    didPriceChanged: alertPriceTextField.rx.text.asDriver(),
                                                    viewDidTap: createTap,
                                                    validPrice: validPrice.asDriver(),
                                                    didTapCreate: createButton.rx.tap.asDriver()))

      output.didTapCloseButton
         .drive(onNext: { [weak self] in
            self?.alertPriceTextField.resignFirstResponder()
         })
         .disposed(by: disposeBag)

      output.createAlertData
         .drive(onNext: { [weak self] data in
            guard let `self` = self else { return }
            self.isLesserButtonSelected.accept(data.comparison == .lessThanOrEqual)
            self.alertPriceSymbolLabel.text = data.quoteSymbol
            self.alertPriceTextField.text = "\(data.reference)"

            if data.isUpdate {
               self.createButton.setTitle("priceAlert.button.update".localized(), for: .normal)
            }
         })
         .disposed(by: disposeBag)

      output.validPriceText
         .drive(alertPriceTextField.rx.text)
         .disposed(by: disposeBag)

      output.validPriceText
         .drive(validPrice)
         .disposed(by: disposeBag)

      output.alertMessagePriceText
         .drive(alertMessageLabel.rx.text)
         .disposed(by: disposeBag)

      output.viewDidTap
         .drive()
         .disposed(by: disposeBag)

      output.didTapCreate
         .drive()
         .disposed(by: disposeBag)

      let isHidden = output.isLoading
         .do(onNext: { [weak self] _ in
            self?.alertPriceTextField.resignFirstResponder()
         })
         .map { !$0 }

      let loadingIndicatorInput = LoadingIndicatorViewModel.Input(isHidden: isHidden,
                                                                  state: output.loadingIndicatorState)
      _ = loadingIndicator.bind(input: loadingIndicatorInput)

      ThemeProvider.current
         .drive(onNext: { [weak self] theme in
            guard let `self` = self else {
               return
            }

            theme.viewThree.apply(to: self.contentView)
            theme.createAlertButton.apply(to: self.createButton)
            theme.createAlertPriceSymbol.apply(to: self.alertPriceSymbolLabel)
            theme.createAlertTextField.apply(to: self.alertPriceTextField)
         })
         .disposed(by: disposeBag)

      _ = isLesserButtonSelected.asObservable().bind(to: lesserButton.rx.isSelected)
      _ = isLesserButtonSelected.asObservable().map { !$0 }.bind(to: greaterButton.rx.isSelected)

      let didSelectLesserButton = output.didSelectLesserButton
         .do(onNext: { [weak self] in
            guard let `self` = self else {
               return
            }

            self.isLesserButtonSelected.accept(true)
         })

      let didSelectGreaterButton = output.didSelectGreaterButton
         .do(onNext: { [weak self] in
            guard let `self` = self else {
               return
            }

            self.isLesserButtonSelected.accept(false)
         })

      let didSelectLesserOrGreaterButton = Driver.merge([didSelectLesserButton, didSelectGreaterButton])

      Driver.combineLatest(didSelectLesserOrGreaterButton.startWith(()),
                           ThemeProvider.current) { [weak self] _, theme in
         guard let `self` = self else {
            return
         }

         let lesserStyle = self.lesserButton.isSelected
            ? theme.createAlertGreaterSelectedButton
            : theme.createAlertGreaterButton
         let greaterStyle = self.greaterButton.isSelected
            ? theme.createAlertGreaterSelectedButton
            : theme.createAlertGreaterButton
         lesserStyle.apply(to: self.lesserButton)
         greaterStyle.apply(to: self.greaterButton)
      }
      .void()
      .drive()
      .disposed(by: disposeBag)

      RxKeyboard.instance.visibleHeight
         .drive(onNext: { [weak self] keyboardVisibleHeight in
            guard let `self` = self else {
               return
            }
            if self.bottomConstraint.constant == 0 {
               self.bottomConstraint.constant =
                  -keyboardVisibleHeight
            } else {
               self.bottomConstraint.constant = 0
            }
         })
         .disposed(by: disposeBag)

      rx.viewWillTransitionToSize
         .void()
         .asDriver(onErrorJustReturn: ())
         .drive(onNext: { [weak self] in
            self?.alertPriceTextField.resignFirstResponder()
         })
         .disposed(by: disposeBag)
   }
}
