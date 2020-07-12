//
//  UIViewcontrollerRxExt-Test.swift
//  App
//
//  Created by Alvin Choo on 23/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Bitpal
import RxCocoa
import RxSwift
import XCTest

class UIViewcontrollerRxExt_Test: XCTestCase {
   private var viewController: UIViewController!
   private let disposeBag = DisposeBag()
   private var expect: XCTestExpectation!

   override func setUp() {
      expect = expectation(description: "executed")
      viewController = UIViewController()
   }

   func testViewDidLoad() {
      viewController.rx.viewDidLoad.subscribe(onNext: { _ in
         self.expect.fulfill()
      }).disposed(by: disposeBag)

      viewController.viewDidLoad()

      waitForExpectations(timeout: 1) { error in
         XCTAssertNil(error)
      }
   }

   func testViewWillAppearFalse() {
      viewController.rx.viewWillAppear.subscribe(onNext: { value in
         XCTAssertFalse(value)
         self.expect.fulfill()
      }).disposed(by: disposeBag)

      viewController.viewWillAppear(false)

      waitForExpectations(timeout: 1) { error in
         XCTAssertNil(error)
      }
   }

   func testViewWillAppearTrue() {
      viewController.rx.viewWillAppear.subscribe(onNext: { value in
         XCTAssertTrue(value)
         self.expect.fulfill()
      }).disposed(by: disposeBag)

      viewController.viewWillAppear(true)

      waitForExpectations(timeout: 1) { error in
         XCTAssertNil(error)
      }
   }

   func testViewDidAppearFalse() {
      viewController.rx.viewDidAppear.subscribe(onNext: { value in
         XCTAssertFalse(value)
         self.expect.fulfill()
      }).disposed(by: disposeBag)

      viewController.viewDidAppear(false)

      waitForExpectations(timeout: 1) { error in
         XCTAssertNil(error)
      }
   }

   func testViewDidAppearTrue() {
      viewController.rx.viewDidAppear.subscribe(onNext: { value in
         XCTAssertTrue(value)
         self.expect.fulfill()
      }).disposed(by: disposeBag)

      viewController.viewDidAppear(true)

      waitForExpectations(timeout: 1) { error in
         XCTAssertNil(error)
      }
   }

   func testViewWillDisappearFalse() {
      viewController.rx.viewWillDisappear.subscribe(onNext: { value in
         XCTAssertFalse(value)
         self.expect.fulfill()
      }).disposed(by: disposeBag)

      viewController.viewWillDisappear(false)

      waitForExpectations(timeout: 1) { error in
         XCTAssertNil(error)
      }
   }

   func testViewWillDisappearTrue() {
      viewController.rx.viewWillDisappear.subscribe(onNext: { value in
         XCTAssertTrue(value)
         self.expect.fulfill()
      }).disposed(by: disposeBag)

      viewController.viewWillDisappear(true)

      waitForExpectations(timeout: 1) { error in
         XCTAssertNil(error)
      }
   }

   func testViewDidDisappearFalse() {
      viewController.rx.viewDidDisappear.subscribe(onNext: { value in
         XCTAssertFalse(value)
         self.expect.fulfill()
      }).disposed(by: disposeBag)

      viewController.viewDidDisappear(false)

      waitForExpectations(timeout: 1) { error in
         XCTAssertNil(error)
      }
   }

   func testViewDidDisappearTrue() {
      viewController.rx.viewDidDisappear.subscribe(onNext: { value in
         XCTAssertTrue(value)
         self.expect.fulfill()
      }).disposed(by: disposeBag)

      viewController.viewDidDisappear(true)

      waitForExpectations(timeout: 1) { error in
         XCTAssertNil(error)
      }
   }

   func testViewWillLayoutSubviews() {
      viewController.rx.viewWillLayoutSubviews.subscribe(onNext: { _ in
         self.expect.fulfill()
      }).disposed(by: disposeBag)

      viewController.viewWillLayoutSubviews()

      waitForExpectations(timeout: 1) { error in
         XCTAssertNil(error)
      }
   }

   func testViewDidLayoutSubviews() {
      viewController.rx.viewDidLayoutSubviews.subscribe(onNext: { _ in
         self.expect.fulfill()
      }).disposed(by: disposeBag)

      viewController.viewDidLayoutSubviews()

      waitForExpectations(timeout: 1) { error in
         XCTAssertNil(error)
      }
   }

   func testIsVisible() {
      viewController.isVisible.drive(onNext: { visible in
         XCTAssertTrue(visible)
         self.expect.fulfill()
      }).disposed(by: disposeBag)

      viewController.viewWillAppear(true)

      waitForExpectations(timeout: 1) { error in
         XCTAssertNil(error)
      }
   }

   func testIsNotVisible() {
      viewController.isVisible.drive(onNext: { visible in
         XCTAssertFalse(visible)
         self.expect.fulfill()
      }).disposed(by: disposeBag)

      viewController.viewWillDisappear(true)

      waitForExpectations(timeout: 1) { error in
         XCTAssertNil(error)
      }
   }

   func testTopMostViewController() {
      XCTAssertTrue(viewController.topMostViewController == viewController)

      let viewControllerPresented = UIViewController()

      let appDelegate = UIApplication.shared.delegate?.window!
      appDelegate?.rootViewController = viewController

      viewController.present(viewControllerPresented, animated: true, completion: {
         XCTAssertTrue(self.viewController.topMostViewController == viewControllerPresented)
         self.expect.fulfill()
      })

      waitForExpectations(timeout: 1.5) { error in
         XCTAssertNil(error)
      }
   }

   func testSequentialPresentationArrayCount() {
      let appDelegate = UIApplication.shared.delegate?.window!

      appDelegate?.rootViewController = viewController

      viewController.sequentialPresentation(of: []) {
         self.expect.fulfill()
      }

      waitForExpectations(timeout: 1.5) { error in
         XCTAssertNil(error)
      }
   }

   func testSequentialPresentationIsNotDissmiedOrPresenting() {
      let appDelegate = UIApplication.shared.delegate?.window!

      appDelegate?.rootViewController = viewController

      let viewController1 = UIViewController()
      let viewController2 = UIViewController()

      viewController.sequentialPresentation(of: [viewController1, viewController2]) {
         XCTAssertTrue(self.viewController.topMostViewController == viewController2)
         self.expect.fulfill()
      }

      waitForExpectations(timeout: 1.5) { error in
         XCTAssertNil(error)
      }
   }

   func testSequentialPresentationIsDissmiedOrPresenting() {
      let appDelegate = UIApplication.shared.delegate?.window!

      appDelegate?.rootViewController = viewController

      let viewController1 = UIViewController()
      let viewController2 = UIViewController()

      viewController.present(viewController1, animated: true, completion: nil)

      viewController.sequentialPresentation(of: [viewController2]) {
         XCTAssertTrue(self.viewController.topMostViewController == viewController2)
         self.expect.fulfill()
      }

      waitForExpectations(timeout: 1.5) { error in
         XCTAssertNil(error)
      }
   }

   func testSequentialPresentOnTop() {
      let appDelegate = UIApplication.shared.delegate?.window!

      appDelegate?.rootViewController = viewController

      let presentedViewController = UIViewController()

      viewController.presentOnTop(presentedViewController) {
         XCTAssertTrue(self.viewController.topMostViewController == presentedViewController)
         self.expect.fulfill()
      }

      waitForExpectations(timeout: 1.5) { error in
         XCTAssertNil(error)
      }
   }

   func testSequentialDismissEmpty() {
      let appDelegate = UIApplication.shared.delegate?.window!

      appDelegate?.rootViewController = viewController

      viewController.sequentialDismiss {
         XCTAssertTrue(self.viewController.topMostViewController == self.viewController)
         self.expect.fulfill()
      }

      waitForExpectations(timeout: 1.5) { error in
         XCTAssertNil(error)
      }
   }

   func testSequentialDismiss() {
      let appDelegate = UIApplication.shared.delegate?.window!

      appDelegate?.rootViewController = viewController

      let viewControllerPresented = UIViewController()

      viewController.present(viewControllerPresented, animated: false, completion: nil)

      viewController.sequentialDismiss {
         XCTAssertTrue(self.viewController.topMostViewController == self.viewController)
         self.expect.fulfill()
      }

      waitForExpectations(timeout: 1.5) { error in
         XCTAssertNil(error)
      }
   }
}
