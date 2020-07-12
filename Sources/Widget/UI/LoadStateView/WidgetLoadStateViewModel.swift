//
//  WidgetLoadStateViewModel.swift
//  Widget
//
//  Created by James Lai on 8/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxCocoa
import RxSwift

class WidgetLoadStateViewModel {
   enum State {
      case empty
      case error

      var title: String {
         switch self {
         case .empty:
            return "widget.watchlist.empty.title".localized()
         case .error:
            return "widget.watchlist.noDB.title".localized()
         }
      }

      var message: String {
         switch self {
         case .empty:
            return "widget.watchlist.empty.message".localized()
         case .error:
            return "widget.watchlist.noDB.message".localized()
         }
      }
   }

   struct Input {
      let loadState: LoadState
   }

   struct Output {
      let loadState: LoadState
      let title: Driver<String>
      let message: Driver<String>

      /// - parameter states: The states to check.
      /// - returns: True if all states are set.
      private func isIn(_ states: LoadState) -> Driver<Bool> {
         return Driver.just(loadState == states)
      }

      var isLoading: Driver<Bool> {
         return isIn(.loading)
      }

      /// True if the `LoadStateView` is hidden.
      var isHidden: Driver<Bool> {
         return isIn(.ready)
      }
   }

   func transform(input: Input) -> Output {
      // now only have 1 case, use loadstate to decide the case
      let state = input.loadState == .emptyWatchlist || input.loadState == .empty ? State.empty : State.error
      let title = Driver.just(state.title)
      let message = Driver.just(state.message)

      return .init(loadState: input.loadState, title: title, message: message)
   }
}
