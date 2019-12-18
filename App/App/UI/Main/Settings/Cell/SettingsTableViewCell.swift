//
//  SettingsTableViewCell.swift
//  App
//
//  Created by Kok Hong Choo on 21/7/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import RxCocoa
import RxSwift
import UIKit

final class SettingsTableViewModel: ViewModelType {
   struct Input {
      let settingsData: Driver<SettingListData>
      let switchDriver: Driver<Bool>
   }

   struct Output {
      let title: Driver<String>
      let description: Driver<String>
      let switchValue: Driver<Bool>
      let isNavigable: Driver<Bool>
      let isSwitchable: Driver<Bool>
      let switchDriver: Driver<Void>
   }

   func transform(input: Input) -> Output {
      let title = input.settingsData.map { $0.title }
      let description = input.settingsData.map { $0.description }
      let switchValue = input.settingsData.map { $0.switchValue }
      let isNavigable = input.settingsData.map { $0.navigable }
      let isSwitchable = input.settingsData.map { $0.switchable }
      let switchDriver = input.switchDriver.withLatestFrom(input.settingsData) { ($0, $1) }
         .do(onNext: { isOn, settingsData in
            settingsData.switchValueChanged(isOn: isOn)
         })
         .void()

      return Output(title: title,
                    description: description,
                    switchValue: switchValue,
                    isNavigable: isNavigable,
                    isSwitchable: isSwitchable,
                    switchDriver: switchDriver)
   }
}

final class SettingsTableViewCell: UITableViewCell, ViewType {
   private enum Metric {
      static let seperatorHeight: CGFloat = 1.0
      static let titleLeading: CGFloat = 24.0
      static let descriptionTrailing: CGFloat = 19.0
      static let nextImageRatio: CGFloat = 14.3 / 8.0
      static let nextImageWidth: CGFloat = 8.0
      static let switchWidth: CGFloat = 50
      static let switchHeight: CGFloat = 30
   }

   var settingsData = BehaviorRelay<SettingListData?>(value: nil)

   var viewModel: SettingsTableViewModel!

   var disposeBag: DisposeBag!

   public static let identifier = String(describing: SettingsTableViewCell.self)

   override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
      super.init(style: style, reuseIdentifier: reuseIdentifier)
      viewModel = SettingsTableViewModel()
      disposeBag = DisposeBag()
      layout()
      bind()
   }

   required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
   }

   private lazy var displayTitleLabel: UILabel = {
      let label = UILabel()
      label.translatesAutoresizingMaskIntoConstraints = false
      label.setAccessibility(id: .settingsCellTitleLabel)
      return label
   }()

   private lazy var descriptionLabel: UILabel = {
      let label = UILabel()
      label.translatesAutoresizingMaskIntoConstraints = false
      Style.Label.settingsDescriptionLabel.apply(to: label)
      label.setAccessibility(id: .settingsCellDescriptionLabel)
      return label
   }()

   private lazy var nextImageView: UIImageView = {
      let imageView = UIImageView(image: Image.nextIcon.resource)
      imageView.tintColor = Color.warmGreyThree
      imageView.translatesAutoresizingMaskIntoConstraints = false
      imageView.setAccessibility(id: .settingsCellDisclosure)
      return imageView
   }()

   private lazy var switchView: UISwitch = {
      let switchView = UISwitch()
      switchView.tintColor = Color.tealish
      switchView.onTintColor = Color.tealish
      switchView.translatesAutoresizingMaskIntoConstraints = false
      return switchView
   }()

   private lazy var mediumHapticGenerator: UIImpactFeedbackGenerator = {
      UIImpactFeedbackGenerator(style: .medium)
   }()

   func layout() {
      [displayTitleLabel, descriptionLabel, nextImageView, switchView]
         .forEach(contentView.addSubview)

      NSLayoutConstraint.activate([
         displayTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                    constant: Metric.titleLeading),
         displayTitleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

         descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                    constant: -Metric.descriptionTrailing),
         descriptionLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

         nextImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                 constant: -Metric.descriptionTrailing),
         nextImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
         nextImageView.heightAnchor.constraint(equalTo: nextImageView.widthAnchor,
                                               multiplier: Metric.nextImageRatio),
         nextImageView.widthAnchor.constraint(equalToConstant: Metric.nextImageWidth),

         switchView.widthAnchor.constraint(equalToConstant: Metric.switchWidth),
         switchView.heightAnchor.constraint(equalToConstant: Metric.switchHeight),
         switchView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
         switchView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                              constant: -Metric.descriptionTrailing)
      ])
      selectionStyle = .none
   }

   func bind() {
      let switchDriver = switchView.rx.isOn.asDriver()

      let output = viewModel.transform(input: .init(settingsData: settingsData.asDriver().filterNil(),
                                                    switchDriver: switchDriver))

      output.description
         .drive(descriptionLabel.rx.text)
         .disposed(by: disposeBag)

      output.title
         .drive(displayTitleLabel.rx.text)
         .disposed(by: disposeBag)

      output.switchValue
         .drive(switchView.rx.isOn)
         .disposed(by: disposeBag)

      Driver.zip(output.isNavigable, output.isSwitchable) {
         $0 || $1
      }
      .drive(descriptionLabel.rx.isHidden)
      .disposed(by: disposeBag)

      output.isNavigable.not()
         .drive(nextImageView.rx.isHidden)
         .disposed(by: disposeBag)

      output.isSwitchable.not()
         .drive(switchView.rx.isHidden)
         .disposed(by: disposeBag)

      output.switchDriver
         .drive(onNext: mediumHapticGenerator.impactOccurred)
         .disposed(by: disposeBag)

      ThemeProvider.current
         .drive(onNext: { theme in
            theme.settingsTitleLabel.apply(to: self.displayTitleLabel)
         })
         .disposed(by: disposeBag)
   }

   override func prepareForReuse() {
      super.prepareForReuse()
      descriptionLabel.text = nil
      displayTitleLabel.text = nil
      descriptionLabel.isHidden = true
      nextImageView.isHidden = true
      switchView.isHidden = true
   }
}
