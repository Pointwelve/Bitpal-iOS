//
//  WebKitExt-Tests.swift
//  App
//
//  Created by Alvin Choo on 24/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Bitpal
import RxCocoa
import RxSwift
import WebKit
import XCTest

class WebKitExt_Tests: XCTestCase {
   private let disposeBag = DisposeBag()

   func testTitleObservable() {
      let webView = WKWebView()

      let html = "<html><head></head><body>abc</body></html>"
      webView.loadHTMLString(html, baseURL: nil)

      let expect = expectation(description: "executed")
      webView.rx.title.subscribe(onNext: { title in
         XCTAssertTrue(title == "")
         expect.fulfill()
      }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1.0) { error in
         XCTAssertNil(error)
      }
   }

   // TODO: kokhong 25/05/2017 Fix test case
   //   func testIsLoadingObservable() {
//      let webView = WKWebView()
//
//      let html = "<html><head></head><body>abc</body></html>"
//      webView.loadHTMLString(html, baseURL: URL(string: "test")!)
//
//      var count = 0
//      let expect = expectation(description: "executed")
//      webView.rx.isLoading.subscribe(onNext: { loading in
//         count += 1
//         if count == 1 {
//            XCTAssertTrue(loading)
//         }
//         if count == 2 {
//            XCTAssertFalse(loading)
//            expect.fulfill()
//         }
//      }).disposed(by: disposeBag)
//
//      waitForExpectations(timeout: 1.0) { error in
//         XCTAssertNil(error)
//      }
   //   }

   func testUrlObservable() {
      let webView = WKWebView()

      let html = "<html><head></head><body>abc</body></html>"
      webView.loadHTMLString(html, baseURL: URL(string: "test")!)

      let expect = expectation(description: "executed")
      webView.rx.url.subscribe(onNext: { url in
         XCTAssertTrue(url == URL(string: "test"))
         expect.fulfill()
      }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1.0) { error in
         XCTAssertNil(error)
      }
   }

   func testEstimatedProgressObservable() {
      let webView = WKWebView()

      let html = "<html><head></head><body>abc</body></html>"
      webView.loadHTMLString(html, baseURL: URL(string: "test")!)

      let expect = expectation(description: "executed")
      webView.rx.estimatedProgress.take(1).subscribe(onNext: { progress in
         XCTAssertTrue(progress > 0)
         expect.fulfill()
      }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1.0) { error in
         XCTAssertNil(error)
      }
   }

   func testEstimatedCanGoBackObservable() {
      let webView = WKWebView()

      let html = "<html><head></head><body>abc</body></html>"
      webView.loadHTMLString(html, baseURL: URL(string: "test")!)

      let expect = expectation(description: "executed")
      webView.rx.canGoBack.subscribe(onNext: { goBack in
         XCTAssertFalse(goBack)
         expect.fulfill()
      }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1.0) { error in
         XCTAssertNil(error)
      }
   }

   func testEstimatedCanGoForwardObservable() {
      let webView = WKWebView()

      let html = "<html><head></head><body>abc</body></html>"
      webView.loadHTMLString(html, baseURL: URL(string: "test")!)

      let expect = expectation(description: "executed")
      webView.rx.canGoForward.subscribe(onNext: { goForward in
         XCTAssertFalse(goForward)
         expect.fulfill()
      }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1.0) { error in
         XCTAssertNil(error)
      }
   }

//   func testWebViewDelegate() {
//      let webView = WKWebView()
//      let controller = WKController(nibName: nil, bundle: nil)
//
//      RxWKNavigationDelegateProxy.setCurrentDelegate(controller, to: webView)
//   }
}

private class WKController: UIViewController, WKNavigationDelegate {}
