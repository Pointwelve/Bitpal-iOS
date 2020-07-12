//
//  UIViewController+Rx.swift
//  App
//
//  Created by Ryne Cheow on 2/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import RxCocoa
import RxSwift
import UIKit

extension Reactive where Base: UIViewController {
   var viewDidLoad: Observable<Void> {
      return sentMessage(#selector(Base.viewDidLoad)).map { _ in
         Void()
      }
   }

   var viewWillAppear: Observable<Bool> {
      return sentMessage(#selector(Base.viewWillAppear)).map {
         $0.first as? Bool ?? false
      }
   }

   var viewDidAppear: Observable<Bool> {
      return sentMessage(#selector(Base.viewDidAppear)).map {
         $0.first as? Bool ?? false
      }
   }

   var viewWillDisappear: Observable<Bool> {
      return sentMessage(#selector(Base.viewWillDisappear)).map {
         $0.first as? Bool ?? false
      }
   }

   var viewDidDisappear: Observable<Bool> {
      return sentMessage(#selector(Base.viewDidDisappear)).map {
         $0.first as? Bool ?? false
      }
   }

   var viewWillLayoutSubviews: Observable<Void> {
      return sentMessage(#selector(Base.viewWillLayoutSubviews)).map { _ in
         Void()
      }
   }

   var viewDidLayoutSubviews: Observable<Void> {
      return sentMessage(#selector(Base.viewDidLayoutSubviews)).map { _ in
         Void()
      }
   }

   var viewWillTransitionToSize: Observable<CGSize> {
      return sentMessage(#selector(Base.viewWillTransition(to:with:))).map {
         $0.first as? CGSize ?? CGSize.zero
      }
   }
}

extension UIViewController {
   var willBecomeVisible: Driver<Bool> {
      let appear = willAppear.map { _ in true }
      let disappear = willDisappear.map { _ in false }
      return Observable.merge(appear, disappear).asDriver(onErrorJustReturn: false).distinctUntilChanged()
   }

   var didBecomeVisible: Driver<Bool> {
      let appear = didAppear.map { _ in true }
      let disappear = didDisappear.map { _ in false }
      return Observable.merge(appear, disappear).asDriver(onErrorJustReturn: false).distinctUntilChanged()
   }

   var didAppear: Observable<Void> {
      return rx.sentMessage(#selector(UIViewController.viewDidAppear(_:))).void().share()
   }

   var didDisappear: Observable<Void> {
      return rx.sentMessage(#selector(UIViewController.viewDidDisappear(_:))).void().share()
   }

   var willAppear: Observable<Void> {
      return rx.sentMessage(#selector(UIViewController.viewWillAppear(_:))).void().share()
   }

   var willDisappear: Observable<Void> {
      return rx.sentMessage(#selector(UIViewController.viewWillDisappear(_:))).void().share()
   }
}

extension UIViewController {
   var isVisible: Driver<Bool> {
      let appear = rx.sentMessage(#selector(UIViewController.viewWillAppear(_:))).map { _ in true }
      let disappear = rx.sentMessage(#selector(UIViewController.viewWillDisappear(_:))).map { _ in false }
      return Observable.merge(appear, disappear).asDriver(onErrorJustReturn: false).distinctUntilChanged()
   }

   var topMostViewController: UIViewController {
      var topMost = self
      while let topMostPresented = topMost.presentedViewController {
         topMost = topMostPresented
      }
      return topMost
   }

   private var sequentialPresentedViewControllers: [UIViewController] {
      var orderToDismiss = [UIViewController]()
      var topMost = self
      while let topMostPresented = topMost.presentedViewController {
         orderToDismiss.append(topMost)
         topMost = topMostPresented
      }
      return orderToDismiss.reversed()
   }

   private var alreadyPresentingOrDismissing: Bool {
      let topMost = topMostViewController
      return topMost.isBeingPresented || topMost.presentedViewController?.isBeingPresented == true ||
         topMost.isBeingDismissed || topMost.presentedViewController?.isBeingDismissed == true
   }

   /// Present view controller on top of stack when possible.
   /// - parameter viewController: View Controller to present.
   /// - parameter animated: Whether or not to animate presentation of the view controller.
   /// - parameter completion: Called once the `viewController` has been presented.
   func presentOnTop(_ viewController: UIViewController,
                     animated: Bool = true,
                     completion: (() -> Void)? = nil) {
      sequentialPresentation(of: [viewController], animated: animated, completion: completion)
   }

   /// Present view controllers in sequence on top of stack then call completion
   /// once final view controller has been presented.
   /// - parameter viewControllers: View Controllers in order they should be presented.
   /// - parameter animated: Whether or not to animate presentation of each view controller.
   /// - parameter completion: Called once all `viewControllers` have been presented.
   func sequentialPresentation(of viewControllers: [UIViewController],
                               animated: Bool = true,
                               completion: (() -> Void)? = nil) {
      guard !viewControllers.isEmpty else {
         completion?()
         return
      }
      if alreadyPresentingOrDismissing {
         DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.sequentialPresentation(of: viewControllers, animated: animated, completion: completion)
         }
         return
      }
      var toPresent = viewControllers
      let current = toPresent.removeFirst()
      topMostViewController.present(current, animated: animated) {
         current.sequentialPresentation(of: toPresent, animated: animated, completion: completion)
      }
   }

   /// Dismiss view controllers starting from the top-most view controller working backwards.
   /// - parameter animated: Whether or not to animate dismissal of each view controller.
   /// - parameter completion: Called once all View Controllers have been dismissed.
   func sequentialDismiss(animated: Bool = true,
                          completion: (() -> Void)? = nil) {
      var toDismiss = sequentialPresentedViewControllers

      func dismissFirst(finished: @escaping () -> Void) {
         guard !toDismiss.isEmpty else {
            finished()
            return
         }
         toDismiss.removeFirst().dismiss(animated: animated) {
            dismissFirst(finished: finished)
         }
      }

      dismissFirst {
         completion?()
      }
   }
}
