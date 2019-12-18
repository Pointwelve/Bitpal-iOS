//
//  LoadingIndicator.swift
//  App
//
//  Created by Li Hao Lai on 29/10/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import NVActivityIndicatorView
import RxCocoa
import RxSwift
import UIKit

final class LoadingIndicator: UIView, IOBindable {
   var disposeBag: DisposeBag! = DisposeBag()

   private lazy var contentView: UIView = {
      let view = UIView()
      view.translatesAutoresizingMaskIntoConstraints = false
      view.layer.cornerRadius = 26.0
      view.layer.borderWidth = 1.0
      view.layer.borderColor = UIColor.clear.cgColor

      return view
   }()

   private lazy var activityIndicatorView: NVActivityIndicatorView = {
      let activityIndicatorView = NVActivityIndicatorView(frame: .init(x: 0,
                                                                       y: 0,
                                                                       width: 50,
                                                                       height: 50),
                                                          type: .ballClipRotate,
                                                          color: Color.coolGreyTwo,
                                                          padding: 0)
      activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
      activityIndicatorView.alpha = 0.0
      activityIndicatorView.startAnimating()
      return activityIndicatorView
   }()

   private var contentViewHeightConstraint: NSLayoutConstraint!
   private var contentViewWidthConstraint: NSLayoutConstraint!

   private var dimissCompletion = BehaviorRelay<(() -> Void)?>(value: nil)

   override init(frame: CGRect) {
      super.init(frame: frame)
      layout()
   }

   required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
   }

   func layout() {
      [contentView].forEach(addSubview)
      [activityIndicatorView].forEach(contentView.addSubview)

      contentViewWidthConstraint = contentView.widthAnchor.constraint(equalToConstant: 0.0)
      contentViewHeightConstraint = contentView.heightAnchor.constraint(equalToConstant: 0.0)

      NSLayoutConstraint.activate([
         contentViewWidthConstraint,
         contentViewHeightConstraint,
         contentView.centerXAnchor.constraint(equalTo: centerXAnchor),
         contentView.centerYAnchor.constraint(equalTo: centerYAnchor),

         activityIndicatorView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
         activityIndicatorView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
      ])
   }

   func bind(input: LoadingIndicatorViewModel.Input) -> LoadingIndicatorViewModel.Output {
      let viewModel = LoadingIndicatorViewModel()
      let output = viewModel.transform(input: input)

      output.state
         .drive(onNext: { [weak self] state in
            self?.dimissCompletion.accept(state.completion)
         })
         .disposed(by: disposeBag)

      output.isHidden
         .drive(onNext: { [weak self] in
            $0 ? self?.hide() : self?.show()
         })
         .disposed(by: disposeBag)

      ThemeProvider.current.asDriver()
         .drive(onNext: { [weak self] theme in
            guard let `self` = self else { return }

            theme.loadingIndicatorOverlayView.apply(to: self)
            theme.viewThree.apply(to: self.contentView)
         })
         .disposed(by: disposeBag)

      return output
   }

   private func show() {
      isHidden = false

      guard let keyWindow = UIApplication.shared.keyWindow else {
         return
      }

      keyWindow.addSubview(self)

      NSLayoutConstraint.activate([
         self.topAnchor.constraint(equalTo: keyWindow.topAnchor),
         self.leadingAnchor.constraint(equalTo: keyWindow.leadingAnchor),
         self.trailingAnchor.constraint(equalTo: keyWindow.trailingAnchor),
         self.bottomAnchor.constraint(equalTo: keyWindow.bottomAnchor)
      ])

      UIView.animate(withDuration: 0.3) { [weak self] in
         guard let `self` = self else {
            return
         }

         self.activityIndicatorView.alpha = 1.0
         self.contentViewWidthConstraint.constant = 120.0
         self.contentViewHeightConstraint.constant = 120.0
      }
   }

   private func hide() {
      UIView.animate(withDuration: 0.3, animations: { [weak self] in
         guard let `self` = self else {
            return
         }

         self.activityIndicatorView.alpha = 0.0
         self.contentViewWidthConstraint.constant = 0.0
         self.contentViewHeightConstraint.constant = 0.0
         self.layoutIfNeeded()
      }, completion: { [weak self] isCompleted in
         if isCompleted {
            self?.isHidden = true
            self?.dimissCompletion.value?()
            self?.removeFromSuperview()
         }
      })
   }
}
