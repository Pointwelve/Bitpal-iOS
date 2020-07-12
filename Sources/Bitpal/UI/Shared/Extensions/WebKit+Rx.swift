//
//  WebKit+Rx.swift
//  App
//
//  Created by Ryne Cheow on 2/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import WebKit

extension Reactive where Base: WKWebView {
   /// Reactive wrapper for `title` property
   public var title: Observable<String?> {
      return observe(String.self, "title")
   }

   /// Reactive wrapper for `loading` property.
   public var isLoading: Observable<Bool> {
      return observe(Bool.self, "loading")
         .map {
            $0 ?? false
         }
   }

   /// Reactive wrapper for `estimatedProgress` property.
   public var estimatedProgress: Observable<Double> {
      return observe(Double.self, "estimatedProgress")
         .map {
            $0 ?? 0.0
         }
   }

   /// Reactive wrapper for `url` property.
   public var url: Observable<URL?> {
      return observe(URL.self, "URL")
   }

   /// Reactive wrapper for `canGoBack` property.
   public var canGoBack: Observable<Bool> {
      return observe(Bool.self, "canGoBack")
         .map {
            $0 ?? false
         }
   }

   /// Reactive wrapper for `canGoForward` property.
   public var canGoForward: Observable<Bool> {
      return observe(Bool.self, "canGoForward")
         .map {
            $0 ?? false
         }
   }
}

class RxWKNavigationDelegateProxy:
   DelegateProxy<WKWebView, WKNavigationDelegate>,
   DelegateProxyType,
   WKNavigationDelegate {
   /// Typed parent object.
   public private(set) weak var webView: WKWebView?

   /// - parameter tabBar: Parent object for delegate proxy.
   public init(webView: ParentObject) {
      self.webView = webView
      super.init(parentObject: webView, delegateProxy: RxWKNavigationDelegateProxy.self)
   }

   // Register known implementations
   public static func registerKnownImplementations() {
      register { RxWKNavigationDelegateProxy(webView: $0) }
   }

   static func currentDelegate(for object: WKWebView) -> WKNavigationDelegate? {
      return object.navigationDelegate
   }

   static func setCurrentDelegate(_ delegate: WKNavigationDelegate?, to object: WKWebView) {
      object.navigationDelegate = delegate
   }
}

extension Reactive where Base: WKWebView {
   public var delegate: DelegateProxy<WKWebView, WKNavigationDelegate> {
      return RxWKNavigationDelegateProxy.proxy(for: base)
   }

   public var didCommitNavigation: Observable<(WKWebView, WKNavigation?)> {
      return delegate.methodInvoked(#selector(WKNavigationDelegate.webView(_:didCommit:)))
         .map { params in
            // swiftlint:disable force_cast
            let webView = params[0] as! WKWebView
            let navigation = params[1] as? WKNavigation
            return (webView, navigation)
         }
   }

   public var didFailNavigation: Observable<(WKWebView, WKNavigation?, Error)> {
      return delegate.methodInvoked(#selector(WKNavigationDelegate.webView(_:didFail:withError:)))
         .map { params in
            // swiftlint:disable force_cast
            let webView = params[0] as! WKWebView
            let navigation = params[1] as? WKNavigation
            // swiftlint:disable force_cast
            let error = params[2] as! Error
            return (webView, navigation, error)
         }
   }

   public var didFailProvisionalNavigation: Observable<(WKWebView, WKNavigation?, Error)> {
      return delegate.methodInvoked(#selector(WKNavigationDelegate.webView(_:didFailProvisionalNavigation:withError:)))
         .map { params in
            // swiftlint:disable force_cast
            let webView = params[0] as! WKWebView
            let navigation = params[1] as? WKNavigation
            // swiftlint:disable force_cast
            let error = params[2] as! Error
            return (webView, navigation, error)
         }
   }

   public var didFinishNavigation: Observable<(WKWebView, WKNavigation?)> {
      return delegate.methodInvoked(#selector(WKNavigationDelegate.webView(_:didFinish:)))
         .map { params in
            // swiftlint:disable force_cast
            let webView = params[0] as! WKWebView
            let navigation = params[1] as? WKNavigation
            return (webView, navigation)
         }
   }

   // swiftlint:disable identifier_name
   public var didReceiveServerRedirectForProvisionalNavigation: Observable<(WKWebView, WKNavigation?)> {
      return delegate
         .methodInvoked(#selector(WKNavigationDelegate.webView(_:didReceiveServerRedirectForProvisionalNavigation:)))
         .map { params in
            // swiftlint:disable force_cast
            let webView = params[0] as! WKWebView
            let navigation = params[1] as? WKNavigation
            return (webView, navigation)
         }
   }

   public var didStartProvisionalNavigation: Observable<(WKWebView, WKNavigation?)> {
      return delegate.methodInvoked(#selector(WKNavigationDelegate.webView(_:didStartProvisionalNavigation:)))
         .map { params in
            // swiftlint:disable force_cast
            let webView = params[0] as! WKWebView
            let navigation = params[1] as? WKNavigation
            return (webView, navigation)
         }
   }

   public var webContentProcessDidTerminate: Observable<WKWebView> {
      return delegate.methodInvoked(#selector(WKNavigationDelegate.webViewWebContentProcessDidTerminate(_:)))
         .map { params in
            // swiftlint:disable force_cast
            let webView = params[0] as! WKWebView
            return webView
         }
   }
}
