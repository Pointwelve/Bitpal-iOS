//
//  LoadStateView.swift
//  App
//
//  Created by Ryne Cheow on 15/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxCocoa
import RxSwift

final class LoadStateView: UIView {
   var disposeBag: DisposeBag! = DisposeBag()

   private enum Metric {
      static let labelsSpacing: CGFloat = 20
      static let labelToWidthProportion: CGFloat = 244.0 / 320.0
   }

   private lazy var stackView: UIStackView = {
      let stackView = UIStackView()
      Style.StackView.verticalCentered.apply(to: stackView)
      stackView.spacing = Metric.labelsSpacing
      stackView.translatesAutoresizingMaskIntoConstraints = false
      return stackView
   }()

   lazy var titleLabel: UILabel = {
      let label = UILabel()
      label.setAccessibility(id: .loadStateErrorViewTitle)
      return label
   }()

   lazy var messageLabel: UILabel = {
      let label = UILabel()
      label.setAccessibility(id: .loadStateErrorViewMessage)
      return label
   }()

   lazy var actionButton: UIButton = {
      let button = UIButton(type: .system)
      return button
   }()

   override init(frame: CGRect) {
      super.init(frame: frame)
      layout()
      applyStyle()
   }

   required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
   }

   func layout() {
      [stackView].forEach(addSubview)
      [titleLabel, messageLabel, actionButton].forEach(stackView.addArrangedSubview)

      NSLayoutConstraint.activate([
         stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
         stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
         stackView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: Metric.labelToWidthProportion)
      ])
   }

   func applyStyle() {
      ThemeProvider.current
         .drive(onNext: { [weak self] theme in
            guard let `self` = self else { return }
            theme.backgroundErrorTitle.apply(to: self.titleLabel)
            theme.backgroundErrorMessage.apply(to: self.messageLabel)
            theme.loadStateViewActionButton.apply(to: self.actionButton)
            theme.view.apply(to: self)
         })
         .disposed(by: disposeBag)
   }

   func bind(state: LoadStateViewModel) {
      state.output.isHidden
         .drive(rx.isHidden)
         .disposed(by: disposeBag)

      state.output.title
         .map { $0.attributedString(textAlignment: .center) }
         .drive(titleLabel.rx.attributedText)
         .disposed(by: disposeBag)

      state.output.message
         .map { $0.attributedString(lineHeight: Style.LineHeight.backgroundErrorMessage,
                                    textAlignment: .center) }
         .drive(messageLabel.rx.attributedText)
         .disposed(by: disposeBag)

      state.output.buttonTitle
         .drive(onNext: { [weak self] buttonTitle in
            guard let `self` = self else {
               return
            }

            guard let title = buttonTitle else {
               self.actionButton.isHidden = true
               return
            }

            self.actionButton.isHidden = false
            self.actionButton.setTitle(title, for: .normal)
         })
         .disposed(by: disposeBag)

      actionButton.rx.tap
         .asDriver()
         .void()
         .drive(onNext: {
            guard let action = state.output.buttonAction else {
               return
            }

            action()
         })
         .disposed(by: disposeBag)
   }

   func bind(state: LoadStateViewModel.Output, animated: Bool = false) {
      if animated {
         state.isHidden
            .map { $0 ? 0.0 : 1.0 }
            .drive(rx.alpha)
            .disposed(by: disposeBag)
      } else {
         state.isHidden
            .drive(rx.isHidden)
            .disposed(by: disposeBag)
      }

      state.title
         .map { $0.attributedString(textAlignment: .center) }
         .drive(titleLabel.rx.attributedText)
         .disposed(by: disposeBag)

      state.message
         .map { $0.attributedString(lineHeight: Style.LineHeight.backgroundErrorMessage,
                                    textAlignment: .center) }
         .drive(messageLabel.rx.attributedText)
         .disposed(by: disposeBag)

      state.buttonTitle
         .drive(onNext: { [weak self] buttonTitle in
            guard let `self` = self else {
               return
            }

            guard let title = buttonTitle else {
               self.actionButton.isHidden = true
               return
            }

            self.actionButton.isHidden = false
            self.actionButton.setTitle(title, for: .normal)
         })
         .disposed(by: disposeBag)

      actionButton.rx.tap
         .asDriver()
         .void()
         .drive(onNext: {
            guard let action = state.buttonAction else {
               return
            }

            action()
         })
         .disposed(by: disposeBag)
   }
}
