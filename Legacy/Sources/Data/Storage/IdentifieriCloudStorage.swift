//
//  IdentifieriCloudStorage.swift
//  Data
//
//  Created by Ryne Cheow on 19/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import CloudKit
import Domain
import Foundation
import RxSwift

final class IdentifieriCloudStorage: IdentifierStorage {
   let container = CKContainer.default()

   override func get(_ key: String) -> Observable<String> {
      return Observable.deferred {
         Observable.create { [weak self] observer in
            self?.container.fetchUserRecordID { recordID, error in
               if let e = error {
                  observer.on(.error(e))
                  return
               }

               guard let recordID = recordID else {
                  observer.on(.error(CloudServiceError.recordEmpty))
                  return
               }

               observer.on(.next(recordID.recordName))
               observer.on(.completed)
            }

            return Disposables.create()
         }
      }
   }
}
