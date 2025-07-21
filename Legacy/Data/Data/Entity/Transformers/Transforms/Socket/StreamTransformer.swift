//
//  StreamTransformer.swift
//  Data
//
//  Created by Ryne Cheow on 31/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxSwift

enum StreamTransformer {
   typealias StreamTransformerType<T: DataType & StreamDeserializable> = (Any) -> ValueTransformerBox<String, T>

   fileprivate static func makeStreamTransformer<T: DataType & StreamDeserializable>() -> StreamTransformerType<T> {
      return { _ in
         makeStreamTransformer(customInitializer: { (data) -> T in
            try T(streamData: data)
         })
      }
   }

   fileprivate static func makeStreamTransformer<T: DataType & StreamDeserializable>
   (customInitializer: @escaping (String) throws -> T) -> ValueTransformerBox<String, T> {
      return ValueTransformerBox<String, T>({ data -> Observable<T> in
         Observable<T?>.just(try? customInitializer(data)).filterNil()
      })
   }

   static func price() -> StreamTransformerType<StreamPriceData> {
      return makeStreamTransformer()
   }
}
