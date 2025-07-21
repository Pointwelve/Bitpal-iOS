//
//  Rx+Operator.swift
//  App
//
//  Created by Kok Hong Choo on 9/10/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import RxCocoa
import RxSwift
import UIKit

// Two way binding operator between control property and variable, that's all it takes {
infix operator <->: DefaultPrecedence

func nonMarkedText(_ textInput: UITextInput) -> String? {
   let start = textInput.beginningOfDocument
   let end = textInput.endOfDocument

   guard let rangeAll = textInput.textRange(from: start, to: end),
      let text = textInput.text(in: rangeAll) else {
      return nil
   }

   guard let markedTextRange = textInput.markedTextRange else {
      return text
   }

   guard let startRange = textInput.textRange(from: start, to: markedTextRange.start),
      let endRange = textInput.textRange(from: markedTextRange.end, to: end) else {
      return text
   }

   return (textInput.text(in: startRange) ?? "") + (textInput.text(in: endRange) ?? "")
}

@discardableResult
func <-> <Base>(textInput: TextInput<Base>, relay: BehaviorRelay<String>)
   -> Disposable {
   let bindToUIDisposable = relay.asObservable()
      .bind(to: textInput.text)
   let bindToVariable = textInput.text
      .subscribe(onNext: { [weak base = textInput.base] _ in
         guard let base = base else {
            return
         }

         let nonMarkedTextValue = nonMarkedText(base)

         /**
          In some cases `textInput.textRangeFromPosition(start, toPosition: end)`
          will return nil even though the underlying value is not nil.
          This appears to be an Apple bug. If it's not, and we are doing something
          wrong, please let us know.

          The can be reproed easily if replace bottom code with

          if nonMarkedTextValue != variable.value {
          variable.value = nonMarkedTextValue ?? ""
          }
          and you hit "Done" button on keyboard.
          */
         if let nonMarkedTextValue = nonMarkedTextValue, nonMarkedTextValue != relay.value {
            relay.accept(nonMarkedTextValue)
         }
      }, onCompleted: {
         bindToUIDisposable.dispose()
      })

   return Disposables.create(bindToUIDisposable, bindToVariable)
}

@discardableResult
func <-> <T>(property: ControlProperty<T>, relay: BehaviorRelay<T>) -> Disposable {
   if T.self == String.self {
      fatalError("")
   }

   let bindToUIDisposable = relay.asObservable()
      .bind(to: property)
   let bindToVariable = property
      .subscribe(onNext: { n in
         relay.accept(n)
      }, onCompleted: {
         bindToUIDisposable.dispose()
      })

   return Disposables.create(bindToUIDisposable, bindToVariable)
}
