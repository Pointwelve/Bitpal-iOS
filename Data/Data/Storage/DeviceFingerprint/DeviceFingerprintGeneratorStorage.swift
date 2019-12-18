//
//  DeviceFingerprintGeneratorStorage.swift
//  Data
//
//  Created by Ryne Cheow on 5/7/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxSwift

final class DeviceFingerprintGenerator: DeviceFingerprintStorage {
   typealias Object = DeviceFingerprintData

   override func get(_ key: String) -> Observable<DeviceFingerprintData> {
      #if targetEnvironment(simulator)
         return .just(DeviceFingerprintData(data: "Bitpal_Dev_Simulator"))
      #else
         return .just(DeviceFingerprintData(data: "anon_ios_\(Int(Date().timeIntervalSince1970))_\(UUID().uuidString)"))
      #endif
   }
}
