//
//  WidgetLoadStateView.swift
//  Widget
//
//  Created by James Lai on 8/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import RxCocoa
import RxSwift
import UIKit

final class WidgetLoadStateView: UIView {
   private enum Metric {
      static let titleLabelTop: CGFloat = 34.0
      static let messageLabelTop: CGFloat = 11.0
   }

   let disposeBag = DisposeBag()

   var viewModel: WidgetLoadStateView!

   private lazy var titleLable: UILabel = {
      let label = UILabel()
      label.translatesAutoresizingMaskIntoConstraints = false
      Style.Label.loadStateTitleLabel.apply(to: label)

      return label
   }()

   private lazy var messageLabel: UILabel = {
      let label = UILabel()
      label.translatesAutoresizingMaskIntoConstraints = false
      Style.Label.loadStateMessageLabel.apply(to: label)

      return label
   }()

   override init(frame: CGRect) {
      super.init(frame: frame)

      layout()
   }

   required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
   }

   func layout() {
      [titleLable, messageLabel].forEach(addSubview)

      NSLayoutConstraint.activate([
         titleLable.topAnchor.constraint(equalTo: self.topAnchor, constant: Metric.titleLabelTop),
         titleLable.leadingAnchor.constraint(equalTo: self.leadingAnchor),
         titleLable.trailingAnchor.constraint(equalTo: self.trailingAnchor),

         messageLabel.topAnchor.constraint(equalTo: titleLable.bottomAnchor, constant: Metric.messageLabelTop),
         messageLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor),
         messageLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor)
      ])
   }

   func bind(viewModel: WidgetLoadStateViewModel, loadState: LoadState) {
      let output = viewModel.transform(input: .init(loadState: loadState))

      output.isHidden.drive(rx.isHidden).disposed(by: disposeBag)
      output.title.drive(titleLable.rx.text).disposed(by: disposeBag)
      output.message.drive(messageLabel.rx.text).disposed(by: disposeBag)
   }
}
