//
//  PopupView.swift
//  App
//
//  Created by James Lai on 22/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import RxCocoa
import RxSwift
import UIKit

class PopupView: UIView {
   var disposeBag = DisposeBag()

   private enum Metrics {
      static let contentViewLeading: CGFloat = 10.0
      static let contentViewTrailing: CGFloat = -10.0
      static let titleTop: CGFloat = 27.0
      static let messageTop: CGFloat = 21.0
      static let messageLeading: CGFloat = 32.0
      static let messageTrailing: CGFloat = -32.0
      static let buttonTop: CGFloat = 32.0
      static let buttonHeight: CGFloat = 53.0
   }

   private lazy var contentView: UIView = {
      let view = UIView()
      view.translatesAutoresizingMaskIntoConstraints = false

      return view
   }()

   private lazy var backgroundView: UIVisualEffectView = {
      let view = UIVisualEffectView()
      view.translatesAutoresizingMaskIntoConstraints = false

      return view
   }()

   private lazy var titleLabel: UILabel = {
      let label = UILabel()
      label.translatesAutoresizingMaskIntoConstraints = false

      return label
   }()

   private lazy var messageLabel: UILabel = {
      let label = UILabel()
      label.translatesAutoresizingMaskIntoConstraints = false

      return label
   }()

   private lazy var defaultButton: UIButton = {
      let button = UIButton(type: .system)
      button.translatesAutoresizingMaskIntoConstraints = false

      return button
   }()

   private lazy var cancelButton: UIButton = {
      let button = UIButton(type: .system)
      button.translatesAutoresizingMaskIntoConstraints = false

      return button
   }()

   private var titleAttributedText: NSAttributedString?

   private var messageAttributedText: NSAttributedString?

   var defaultButtonTappedDriver: Driver<Void> {
      return defaultButton.rx.tap.asDriver()
   }

   var cancelButtonTappedDriver: Driver<Void> {
      return cancelButton.rx.tap.asDriver()
   }

   func layout() {
      [backgroundView, contentView].forEach(addSubview)
      [titleLabel, messageLabel, defaultButton, cancelButton].forEach(contentView.addSubview)

      NSLayoutConstraint.activate([
         backgroundView.topAnchor.constraint(equalTo: topAnchor),
         backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
         backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
         backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),

         contentView.centerYAnchor.constraint(equalTo: centerYAnchor),
         contentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Metrics.contentViewLeading),
         contentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: Metrics.contentViewTrailing),

         titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Metrics.titleTop),
         titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Metrics.messageLeading),
         titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: Metrics.messageTrailing),

         messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Metrics.messageTop),
         messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Metrics.messageLeading),
         messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: Metrics.messageTrailing),

         cancelButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: Metrics.buttonTop),
         cancelButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
         cancelButton.trailingAnchor.constraint(equalTo: defaultButton.leadingAnchor),
         cancelButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
         cancelButton.heightAnchor.constraint(equalToConstant: Metrics.buttonHeight),

         defaultButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: Metrics.buttonTop),
         defaultButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
         defaultButton.leadingAnchor.constraint(equalTo: cancelButton.trailingAnchor),
         defaultButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
         defaultButton.heightAnchor.constraint(equalToConstant: Metrics.buttonHeight),
         defaultButton.widthAnchor.constraint(equalTo: cancelButton.widthAnchor)
      ])
   }

   func bind(data: PopupData) {
      titleLabel.attributedText = data.title
      titleAttributedText = data.title
      messageLabel.attributedText = data.message
      messageAttributedText = data.message
      defaultButton.setTitle(data.ok, for: .normal)
      cancelButton.setTitle(data.cancel, for: .normal)

      let output = PopupViewModel().transform(input: .init(defaultButtonAction: defaultButtonTappedDriver,
                                                           cancelButtonAction: cancelButtonTappedDriver))

      output.didSelectedAction
         .drive(onNext: { [weak self] _ in
            self?.dismiss()
         })
         .disposed(by: disposeBag)

      ThemeProvider.current
         .drive(onNext: { [weak self] theme in
            guard let `self` = self else {
               return
            }

            theme.popup.apply(to: self.contentView)
            theme.popupBackground.apply(to: self.backgroundView)
            theme.popuoTitle.apply(to: self.titleLabel)
            theme.popupMessage.apply(to: self.messageLabel)
            theme.popupDefault.apply(to: self.defaultButton)
            theme.popupCancel.apply(to: self.cancelButton)

            // after styling will lose attributed value
            self.titleLabel.attributedText = self.titleAttributedText
            self.messageLabel.attributedText = self.messageAttributedText
         })
         .disposed(by: disposeBag)
   }

   override var isHidden: Bool {
      get {
         return super.isHidden
      }

      set(hidden) {
         super.isHidden = hidden

         if !hidden { show() }
      }
   }

   private func show() {
      let originalY = contentView.frame.origin.y
      contentView.frame.origin.y = -1000.0

      UIView.animate(withDuration: 0.33, animations: { [weak self] in
         self?.contentView.frame.origin.y = originalY
      }, completion: nil)
   }

   private func dismiss() {
      UIView.animate(withDuration: 0.33, animations: { [weak self] in
         self?.contentView.frame.origin.y = -1000.0
      }, completion: { completed in
         if completed {
            super.isHidden = true
         }
      })
   }
}
