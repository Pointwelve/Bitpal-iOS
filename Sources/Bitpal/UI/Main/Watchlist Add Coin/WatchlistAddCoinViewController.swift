//
//  WatchlistAddCoinViewController.swift
//  App
//
//  Created by Li Hao Lai on 25/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import RxCocoa
import RxDataSources
import RxSwift

final class WatchlistAddCoinViewController: UIViewController, DefaultViewControllerType {
   fileprivate enum Metric {
      static let leftAnchorMargin: CGFloat = 16.0
      static let rightAnchorMargin: CGFloat = 16.0
      static let titleHeaderHeight: CGFloat = 37.0
      static let clearButtonWidth: CGFloat = 31.5
      static let clearButtonHeight: CGFloat = 17.0
      static let clearButtonRightMargin: CGFloat = 14.5
      static let searchTitleTextFieldHeight: CGFloat = 20.0
      static let searchTextFieldLeading: CGFloat = 14.5
      static let headerBaseFullnameLeftAnchorMargin: CGFloat = 6.0
   }

   fileprivate let tokenizer: Character = "_"

   typealias ViewModel = WatchlistAddCoinViewModel

   var disposeBag = DisposeBag()
   var viewModel: WatchlistAddCoinViewModel!

   private lazy var loadStateView: LoadStateView = {
      let view = LoadStateView()
      view.translatesAutoresizingMaskIntoConstraints = false
      view.isHidden = true
      return view
   }()

   private lazy var tableView: UITableView = {
      let tableView = UITableView()
      tableView.translatesAutoresizingMaskIntoConstraints = false
      tableView.estimatedRowHeight = 40.0
      tableView.rowHeight = UITableView.automaticDimension
      tableView.registerCell(of: WatchlistAddCoinTableViewCell.self)
      tableView.keyboardDismissMode = .onDrag

      return tableView
   }()

   private lazy var searchTitleView: NavigationItemBaseView = {
      let searchTitleView = NavigationItemBaseView(frame: CGRect(x: 0.0,
                                                                 y: 0.0,
                                                                 width: self.view.frame.width,
                                                                 height: Metric.searchTitleTextFieldHeight))

      [self.searchTextField].forEach(searchTitleView.addSubview)
      searchTitleView.autoresizingMask = .flexibleWidth
      if #available(iOS 11.0, *) {
         searchTitleView.translatesAutoresizingMaskIntoConstraints = false
      }

      return searchTitleView
   }()

   private lazy var searchTextField: NavigationItemBaseTextField = {
      let searchTextField = NavigationItemBaseTextField(frame: CGRect(x: 0.0,
                                                                      y: 0.0,
                                                                      width: self.view.frame.width,
                                                                      height: Metric.searchTitleTextFieldHeight))
      searchTextField.translatesAutoresizingMaskIntoConstraints = false
      searchTextField.rightView = self.clearButton
      searchTextField.rightViewMode = .whileEditing
      searchTextField.returnKeyType = .go

      let attributedPlaceholder = NSAttributedString(string: "\("watchlist.addcoin.type".localized()) 'BTC', 'Bitcoin', 'ETH/BTC'",
                                                     attributes: [
                                                        .font: Font.regular16,
                                                        .foregroundColor: Color.pinkishGrey
                                                     ])
      searchTextField.attributedPlaceholder = attributedPlaceholder

      return searchTextField
   }()

   private lazy var clearButton: UIButton = {
      let clearButton = UIButton(frame: CGRect(x: 0,
                                               y: 0,
                                               width: Metric.clearButtonWidth,
                                               height: Metric.clearButtonHeight))
      clearButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: Metric.clearButtonRightMargin)
      clearButton.setImage(Image.closeIcon.resource, for: .normal)
      clearButton.tintColor = Color.tealish
      return clearButton
   }()

   private var loadingIndicator: LoadingIndicator = {
      let view = LoadingIndicator()
      view.translatesAutoresizingMaskIntoConstraints = false
      view.isHidden = true

      return view
   }()

   var dataSource: RxTableViewSectionedReloadDataSource<WatchlistAddCoinListData>?

   func layout() {
      navigationItem.titleView = searchTitleView

      var searchTextFieldLeading: CGFloat = 0.0

      if #available(iOS 11.0, *) {
         // iOS 11 behave differently on autolayout constraint
         searchTextFieldLeading = Metric.searchTextFieldLeading
         navigationItem.largeTitleDisplayMode = .never
      }

      tableView.delegate = self

      [loadStateView, tableView].forEach(view.addSubview)

      NSLayoutConstraint.activate([
         loadStateView.topAnchor.constraint(equalTo: view.topAnchor),
         loadStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
         loadStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
         loadStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

         tableView.topAnchor.constraint(equalTo: view.topAnchor),
         tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
         tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
         tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

         searchTextField.topAnchor.constraint(equalTo: searchTitleView.topAnchor),
         searchTextField.bottomAnchor.constraint(equalTo: searchTitleView.bottomAnchor),
         searchTextField.leadingAnchor.constraint(equalTo: searchTitleView.leadingAnchor,
                                                  constant: searchTextFieldLeading),
         searchTextField.trailingAnchor.constraint(equalTo: searchTitleView.trailingAnchor),
         searchTextField.heightAnchor.constraint(equalToConstant: Metric.searchTitleTextFieldHeight)
      ])
   }

   func bind() {
      let output = viewModel.transform(input:
         .init(tableViewItemObservable: tableView.rx.modelSelected(CurrencyPairGroup.self).asObservable(),
               searchTextFieldObservable: searchTextField.rx.text.asObservable(),
               tapClearButtonObservable: clearButton.rx.tap.asObservable()))

      tableView.rx.itemSelected.asDriver()
         .do(onNext: { [weak self] indexPath in
            self?.tableView.deselectRow(at: indexPath, animated: true)
         })
         .drive()
         .disposed(by: disposeBag)

      let dataSource =
         RxTableViewSectionedReloadDataSource<WatchlistAddCoinListData>(configureCell: { _, tv, ip, item -> UITableViewCell in
            let cell = tv.dequeueReusableCell(withIdentifier: WatchlistAddCoinTableViewCell.identifier, for: ip)
            guard let currencyPairCell = cell as? WatchlistAddCoinTableViewCell else {
               return UITableViewCell()
            }

            currencyPairCell.bind(currencyPairGroup: item)

            return currencyPairCell
         })

      dataSource.titleForHeaderInSection = { [weak self] ds, index in
         guard let `self` = self else {
            return "\(ds.sectionModels[index].header.symbol) \(ds.sectionModels[index].header.localizedFullname)"
         }
         return "\(ds.sectionModels[index].header.symbol)\(self.tokenizer)\(ds.sectionModels[index].header.localizedFullname)"
      }

      self.dataSource = dataSource

      output.watchlistAddCoinListData
         .drive(tableView.rx.items(dataSource: dataSource))
         .disposed(by: disposeBag)

      output.prepareSelectExchange
         .do(onNext: { [weak self] in
            self?.searchTextField.resignFirstResponder()
         })
         .drive()
         .disposed(by: disposeBag)

      output.searchTextFieldDriver
         .debounce(.milliseconds(300))
         .drive()
         .disposed(by: disposeBag)

      output.tapClearButtonDriver
         .drive(onNext: { [weak self] in
            self?.searchTextField.text = nil
            self?.searchTextField.sendActions(for: .valueChanged)
         })
         .disposed(by: disposeBag)

      output.loadStateViewModel.output
         .isContentHidden
         .drive(tableView.rx.isHidden)
         .disposed(by: disposeBag)

      loadStateView.bind(state: output.loadStateViewModel)

      ThemeProvider.current
         .drive(onNext: { [weak self] theme in
            guard let `self` = self else {
               return
            }
            theme.tableView.apply(to: self.tableView)
            theme.search.apply(to: self.searchTextField)
            theme.view.apply(to: self.view)
         })
         .disposed(by: disposeBag)
   }
}

extension WatchlistAddCoinViewController: UITableViewDelegate {
   func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
      let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: Metric.titleHeaderHeight))
      let symbolTitleLabel = UILabel()
      let fullnameTitleLable = UILabel()
      symbolTitleLabel.translatesAutoresizingMaskIntoConstraints = false
      fullnameTitleLable.translatesAutoresizingMaskIntoConstraints = false

      Style.Label.headerBaseSymbolGreyText.apply(to: symbolTitleLabel)

      ThemeProvider.current
         .drive(onNext: { theme in
            theme.exchangeTitleView.apply(to: headerView)
            theme.headerBaseFullname.apply(to: fullnameTitleLable)
         })
         .disposed(by: disposeBag)

      [symbolTitleLabel, fullnameTitleLable].forEach(headerView.addSubview)

      NSLayoutConstraint.activate([
         symbolTitleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor,
                                                   constant: Metric.leftAnchorMargin),
         symbolTitleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

         fullnameTitleLable.leadingAnchor.constraint(equalTo: symbolTitleLabel.trailingAnchor,
                                                     constant: Metric.headerBaseFullnameLeftAnchorMargin),
         fullnameTitleLable.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
      ])

      guard let rawTitle = tableView.dataSource?.tableView!(tableView, titleForHeaderInSection: section) else {
         return headerView
      }

      let titles = rawTitle.split(separator: tokenizer).map { String($0) }

      guard titles.count == 2 else {
         symbolTitleLabel.text = rawTitle
         return headerView
      }

      symbolTitleLabel.text = titles[0]
      fullnameTitleLable.text = titles[1]

      return headerView
   }

   func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
      return Metric.titleHeaderHeight
   }
}
