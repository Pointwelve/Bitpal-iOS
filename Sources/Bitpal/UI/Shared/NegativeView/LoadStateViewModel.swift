//
//  LoadStateViewModel.swift
//  App
//
//  Created by Ryne Cheow on 2/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxCocoa
import RxSwift
/// Manages state of screen, many states are shared across multiple screens so this logic is centralized
/// for ease of reuse.
class LoadStateViewModel: ViewModelType {
   enum Strategy {
      case `default`
      case addCoinSearch
      case alerts
      case search
      case watchlist
      case webpage
      case staticWebpage
      /// This strategy returns whatever it is given
      case manual
   }

   struct Input {
      let strategy: Strategy
      let language: Driver<Language>
      let isOnline: Driver<Bool>

      let loadState: Driver<LoadState>
      let buttonAction: (() -> Void)?

      init(navigator: NavigatorType,
           strategy: Strategy = .default,
           loadState: Driver<LoadState>,
           buttonAction: (() -> Void)? = nil) {
         self.strategy = strategy
         isOnline = navigator.state.preferences.serviceProvider.isOnline.asDriver(onErrorJustReturn: true)
         language = navigator.state.preferences.language
         self.loadState = loadState
         self.buttonAction = buttonAction
      }

      /// Testable Init
      init(navigator: NavigatorType, strategy: Strategy = .default, loadState: Driver<LoadState>,
           isOnline: Driver<Bool>, language: Driver<Language>) {
         self.strategy = strategy
         self.isOnline = isOnline
         self.language = language
         self.loadState = loadState
         buttonAction = nil
      }
   }

   struct Output {
      /// The current states of the screen, note: may be in multiple states.
      let loadState: Driver<LoadState>
      /// True if there is a connection available.
      let isOnline: Driver<Bool>
      /// The title copy to show on the `LoadStateView`.
      let title: Driver<String>
      /// The message body copy to show on the `LoadStateView`.
      let message: Driver<String>

      let buttonTitle: Driver<String?>

      let buttonAction: (() -> Void)?

      /// - parameter states: The states to check.
      /// - returns: True if all states are set.
      private func isIn(_ states: LoadState) -> Driver<Bool> {
         return loadState.map {
            $0.contains(states)
         }
      }

      var isLoading: Driver<Bool> {
         return isIn(.loading)
      }

      /// True if the `LoadStateView` is hidden.
      var isHidden: Driver<Bool> {
         return isIn(.ready)
      }

      /// True if content should be hidden from screen, in favour of `LoadStateView`.
      /// Note: This is not the direct opposite of `isHidden` because a loading state can be present in both scenarios.
      var isContentHidden: Driver<Bool> {
         return loadState.map { !$0.contains(.loading) && !$0.contains(.ready) }
      }

      var isEmpty: Driver<Bool> {
         return loadState.map { $0.contains(.empty) }
      }

      var isPagedContentHidden: Driver<Bool> {
         return loadState.map {
            !$0.contains(.ready)
               && !$0.contains(.pageLoading)
               && !$0.contains(.pageError)
         }
      }
   }

   private var input: Input!
   private(set) var output: Output!

   private let disposeBag = DisposeBag()

   func transform(input: Input) -> Output {
      self.input = input

      let displayLoadState: Driver<LoadState>

      let inputLoadState = Driver.combineLatest(input.loadState, input.isOnline) {
         ($0, $1)
      }
      .map { (loadState, online) -> LoadState in
         var newState = loadState
         newState.setOffline(!online)
         return newState
      }

      switch input.strategy {
      case .manual:
         displayLoadState = inputLoadState.map { $0.prepareForDisplay(strategy: .manual) }

      case .default:
         displayLoadState = inputLoadState.map { $0.prepareForDisplay(strategy: .default) }

      case .webpage:
         displayLoadState = inputLoadState.map { $0.prepareForDisplay(strategy: .web) }

      case .watchlist:
         displayLoadState = inputLoadState.map { $0.prepareForDisplay(strategy: .watchlist) }

      case .search:
         displayLoadState = inputLoadState.map { $0.prepareForDisplay(strategy: .offlineAndReady) }

      case .staticWebpage:
         displayLoadState = inputLoadState.map { $0.prepareForDisplay(strategy: .staticWeb) }

      case .addCoinSearch:
         displayLoadState = inputLoadState.map { $0.prepareForDisplay(strategy: .offlineOnly) }

      case .alerts:
         displayLoadState = inputLoadState.map { $0.prepareForDisplay(strategy: .alerts) }
      }

      let languageState = Driver.combineLatest(input.language, displayLoadState) {
         ($0, $1)
      }
      let title = languageState.map { _, loadState in
         loadState.title
      }
      let message = languageState.map { _, loadState in
         loadState.message
      }
      let buttonTitle = languageState.map { _, loadState in
         loadState.buttonTitle
      }

      output = Output(loadState: displayLoadState,
                      isOnline: input.isOnline,
                      title: title,
                      message: message,
                      buttonTitle: buttonTitle,
                      buttonAction: input.buttonAction)

      return output
   }
}
