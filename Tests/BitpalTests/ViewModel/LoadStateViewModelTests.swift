//
//  LoadStateViewModelTests.swift
//  App
//
//  Created by Alvin Choo on 22/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Bitpal
import Domain
import RxCocoa
import RxSwift
import RxTest
import XCTest

class LoadStateViewModelTests: XCTestCase {
   private let viewModel = LoadStateViewModel()
   private var disposeBag: DisposeBag!
   private var scheduler: TestScheduler!

   override func setUp() {
      disposeBag = DisposeBag()
      scheduler = TestScheduler(initialClock: 0)
   }

   func testLoadStateViewModelIsOnline() {
      let observer = scheduler.createObserver(Bool.self)

      let loadStateDriver = scheduler.createHotObservable([next(100, LoadState.ready)]).asObservable().asDriver(onErrorJustReturn: .empty)

      let isOnlineDriver = scheduler.createHotObservable([next(100, true)]).asObservable().asDriver(onErrorJustReturn: true)

      let language = PublishSubject<Language>().asDriver(onErrorJustReturn: Language.en)

      let input = generateInput(with: loadStateDriver, isOnline: isOnlineDriver, language: language)

      let output = viewModel.transform(input: input)

      output.isOnline.drive(observer).disposed(by: disposeBag)
      scheduler.start()

      XCTAssertEqual(observer.events, [next(100, true)])
   }

   func testLoadStateViewModelIsLoading() {
      let observer = scheduler.createObserver(Bool.self)

      let loadStateDriver = scheduler.createHotObservable([next(100, LoadState.loading)]).asObservable().asDriver(onErrorJustReturn: .loading)

      let isOnlineDriver = scheduler.createHotObservable([next(100, true)]).asObservable().asDriver(onErrorJustReturn: true)

      let language = PublishSubject<Language>().asDriver(onErrorJustReturn: Language.en)

      let input = generateInput(with: loadStateDriver, isOnline: isOnlineDriver, language: language)

      let output = viewModel.transform(input: input)

      output.isLoading.drive(observer).disposed(by: disposeBag)
      scheduler.start()
      XCTAssertEqual(observer.events, [next(100, true)])
   }

   func testLoadStateViewModelIsHidden() {
      let testableObserver = scheduler.createObserver(Bool.self)

      let loadStateDriver = scheduler.createHotObservable([next(100, LoadState.ready)]).asObservable().asDriver(onErrorJustReturn: .empty)

      let isOnlineDriver = scheduler.createHotObservable([next(100, true)]).asObservable().asDriver(onErrorJustReturn: true)

      let language = PublishSubject<Language>().asDriver(onErrorJustReturn: Language.en)

      let input = generateInput(with: loadStateDriver, isOnline: isOnlineDriver, language: language)

      let output = viewModel.transform(input: input)

      output.isHidden.drive(testableObserver).disposed(by: disposeBag)

      let expectedEvent = [next(100, true)]
      scheduler.start()

      XCTAssertEqual(testableObserver.events, expectedEvent)
   }

   func testLoadStateViewModelIsContentNotHidden() {
      let testableObserver = scheduler.createObserver(Bool.self)

      let state: LoadState = [.ready, .loading]

      let loadStateDriver = scheduler.createHotObservable([next(100, state)]).asObservable().asDriver(onErrorJustReturn: state)

      let isOnlineDriver = scheduler.createHotObservable([next(100, true)]).asObservable().asDriver(onErrorJustReturn: true)

      let language = PublishSubject<Language>().asDriver(onErrorJustReturn: Language.en)

      let input = generateInput(with: loadStateDriver, isOnline: isOnlineDriver, language: language)

      let output = viewModel.transform(input: input)

      output.isContentHidden.drive(testableObserver).disposed(by: disposeBag)
      scheduler.start()

      XCTAssertEqual(testableObserver.events, [next(100, false)])
   }

   func testLoadStateViewModelIsContentHidden() {
      let observer = scheduler.createObserver(Bool.self)

      let loadStateDriver = scheduler.createHotObservable([next(100, LoadState.offline)]).asObservable().asDriver(onErrorJustReturn: .offline)

      let isOnlineDriver = scheduler.createHotObservable([next(100, false)]).asObservable().asDriver(onErrorJustReturn: false)

      let language = PublishSubject<Language>().asDriver(onErrorJustReturn: Language.en)

      let input = generateInput(with: loadStateDriver, isOnline: isOnlineDriver, language: language)

      let output = viewModel.transform(input: input)
      output.isContentHidden.drive(observer).disposed(by: disposeBag)

      scheduler.start()
      XCTAssertEqual(observer.events, [next(100, true)])
   }

   func testLoadStateViewModelIsPagedContentNotHidden() {
      let state: LoadState = [.ready, .pageLoading, .pageError]

      let observer = scheduler.createObserver(Bool.self)

      let loadStateDriver = scheduler.createHotObservable([next(100, state)]).asObservable().asDriver(onErrorJustReturn: state)

      let isOnlineDriver = scheduler.createHotObservable([next(100, true)]).asObservable().asDriver(onErrorJustReturn: true)

      let language = PublishSubject<Language>().asDriver(onErrorJustReturn: Language.en)

      let input = generateInput(with: loadStateDriver, isOnline: isOnlineDriver, language: language)

      let output = viewModel.transform(input: input)
      output.isPagedContentHidden.drive(observer).disposed(by: disposeBag)

      scheduler.start()

      XCTAssertEqual(observer.events, [next(100, false)])
   }

   func testLoadStateViewModelIsPagedContentHidden() {
      let observer = scheduler.createObserver(Bool.self)

      let loadStateDriver = scheduler.createHotObservable([next(100, LoadState.offline)]).asObservable().asDriver(onErrorJustReturn: .offline)

      let isOnlineDriver = scheduler.createHotObservable([next(100, false)]).asObservable().asDriver(onErrorJustReturn: false)

      let language = PublishSubject<Language>().asDriver(onErrorJustReturn: Language.en)

      let input = generateInput(with: loadStateDriver, isOnline: isOnlineDriver, language: language)

      let output = viewModel.transform(input: input)

      output.isPagedContentHidden.drive(observer).disposed(by: disposeBag)
      scheduler.start()

      XCTAssertEqual(observer.events, [next(100, true)])
   }

   func testLoadStateViewModelManualStrategy() {
      let observer = scheduler.createObserver(Bool.self)

      let loadStateDriver = scheduler.createHotObservable([next(100, LoadState.offline)]).asObservable().asDriver(onErrorJustReturn: .offline)

      let isOnlineDriver = scheduler.createHotObservable([next(100, false)]).asObservable().asDriver(onErrorJustReturn: false)

      let language = PublishSubject<Language>().asDriver(onErrorJustReturn: Language.en)

      let input = generateInput(with: loadStateDriver, strategy: .manual, isOnline: isOnlineDriver, language: language)

      let output = viewModel.transform(input: input)

      output.isPagedContentHidden.drive(observer).disposed(by: disposeBag)
      scheduler.start()

      XCTAssertEqual(observer.events, [next(100, true)])
   }

   func testLoadStateViewModelSearchStrategy() {
      let observer = scheduler.createObserver(Bool.self)

      let loadStateDriver = scheduler.createHotObservable([next(100, LoadState.offline)]).asObservable().asDriver(onErrorJustReturn: .offline)

      let isOnlineDriver = scheduler.createHotObservable([next(100, false)]).asObservable().asDriver(onErrorJustReturn: false)

      let language = PublishSubject<Language>().asDriver(onErrorJustReturn: Language.en)

      let input = generateInput(with: loadStateDriver, strategy: .search, isOnline: isOnlineDriver, language: language)

      let output = viewModel.transform(input: input)

      output.isPagedContentHidden.drive(observer).disposed(by: disposeBag)
      scheduler.start()

      XCTAssertEqual(observer.events, [next(100, true)])
   }

   func testLoadStateViewModelWebpageStrategy() {
      let observer = scheduler.createObserver(Bool.self)

      let loadStateDriver = scheduler.createHotObservable([next(100, LoadState.offline)]).asObservable().asDriver(onErrorJustReturn: .offline)

      let isOnlineDriver = scheduler.createHotObservable([next(100, false)]).asObservable().asDriver(onErrorJustReturn: false)

      let language = PublishSubject<Language>().asDriver(onErrorJustReturn: Language.en)

      let input = generateInput(with: loadStateDriver, strategy: .webpage, isOnline: isOnlineDriver, language: language)

      let output = viewModel.transform(input: input)

      output.isPagedContentHidden.drive(observer).disposed(by: disposeBag)
      scheduler.start()

      XCTAssertEqual(observer.events, [next(100, false)])
   }

   func testLoadStateViewModelStaticWebPageStrategy() {
      let observer = scheduler.createObserver(Bool.self)

      let loadStateDriver = scheduler.createHotObservable([next(100, LoadState.offline)]).asObservable().asDriver(onErrorJustReturn: .offline)

      let isOnlineDriver = scheduler.createHotObservable([next(100, false)]).asObservable().asDriver(onErrorJustReturn: false)

      let language = PublishSubject<Language>().asDriver(onErrorJustReturn: Language.en)

      let input = generateInput(with: loadStateDriver, strategy: .staticWebpage, isOnline: isOnlineDriver, language: language)

      let output = viewModel.transform(input: input)

      output.isPagedContentHidden.drive(observer).disposed(by: disposeBag)
      scheduler.start()

      XCTAssertEqual(observer.events, [next(100, false)])
   }

   func testLoadStateViewModelTitle() {
      let observer = scheduler.createObserver(String.self)

      let loadStateDriver = scheduler.createHotObservable([next(100, LoadState.empty)]).asObservable().asDriver(onErrorJustReturn: .empty)

      let isOnlineDriver = scheduler.createHotObservable([next(100, true)]).asObservable().asDriver(onErrorJustReturn: true)

      let languageDriver = scheduler.createHotObservable([next(100, Language.en)]).asObservable().asDriver(onErrorJustReturn: Language.en)

      let input = generateInput(with: loadStateDriver, isOnline: isOnlineDriver, language: languageDriver)

      let output = viewModel.transform(input: input)
      output.title.drive(observer).disposed(by: disposeBag)
      scheduler.start()

      XCTAssertEqual(observer.events, [next(100, "empty.view.title".localized())])
   }

   func testLoadStateViewModelMessage() {
      let observer = scheduler.createObserver(String.self)

      let loadStateDriver = scheduler.createHotObservable([next(100, LoadState.empty)]).asObservable().asDriver(onErrorJustReturn: .empty)

      let isOnlineDriver = scheduler.createHotObservable([next(100, true)]).asObservable().asDriver(onErrorJustReturn: true)

      let languageDriver = scheduler.createHotObservable([next(100, Language.en)]).asObservable().asDriver(onErrorJustReturn: Language.en)

      let input = generateInput(with: loadStateDriver, isOnline: isOnlineDriver, language: languageDriver)

      let output = viewModel.transform(input: input)
      output.message.drive(observer).disposed(by: disposeBag)
      scheduler.start()

      XCTAssertEqual(observer.events, [next(100, "empty.view.message".localized())])
   }

   private func generateInput(with loadState: Driver<LoadState>, strategy: LoadStateViewModel.Strategy = .default,
                              isOnline: Driver<Bool>, language: Driver<Language>) -> LoadStateViewModel.Input {
      let appDelegate = UIApplication.shared.delegate as! AppDelegate

      return LoadStateViewModel.Input(navigator: appDelegate.navigator!, strategy: strategy, loadState: loadState, isOnline: isOnline, language: language)
   }
}
