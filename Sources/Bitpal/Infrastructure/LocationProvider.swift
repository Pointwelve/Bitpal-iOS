//
//  LocationProvider.swift
//  App
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import CoreLocation
// swiftlint:disable identifier_name
import Foundation
import RxCocoa
import RxSwift

enum LocationProviderState {
   case unknown
   case denied
   case restricted
   case unavailable
   case allowed
   case determined
   case identifiedCountryIso(String)

   var isUnrecoverableError: Bool {
      switch self {
      case .unavailable:
         return true
      default:
         return false
      }
   }
}

protocol LocationProviderType {
   var state: Driver<LocationProviderState> { get }

   func start()

   func start(timeout: TimeInterval)

   func cancel()

   func stop()
}

extension LocationProviderType {
   func start() {
      start(timeout: 5)
   }
}

final class LocationProvider: NSObject, LocationProviderType {
   fileprivate let geocoder: CLGeocoder
   fileprivate let locationManager: CLLocationManager
   fileprivate let _state = BehaviorRelay<LocationProviderState>(value: .unknown)
   let state: Driver<LocationProviderState>

   private var cancelled: Bool = false

   override init() {
      state = _state.asDriver()

      locationManager = CLLocationManager()
      locationManager.desiredAccuracy = kCLLocationAccuracyBest

      geocoder = CLGeocoder()

      super.init()
   }

   func start(timeout: TimeInterval) {
      cancelled = false
      locationManager.stopUpdatingLocation()
      locationManager.delegate = self
      locationManager.requestWhenInUseAuthorization()
      locationManager.startUpdatingLocation()
      cancel(in: timeout)
   }

   func cancel(in seconds: TimeInterval) {
      if seconds > 0, !cancelled {
         DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if self.cancelled {
               return
            }
            self.cancel(in: seconds - 1)
         }
         return
      }
      cancel()
   }

   func cancel() {
      if case .unavailable = _state.value, cancelled {
         return
      }
      _state.accept(.unavailable)
      stop()
   }

   func stop() {
      if locationManager.delegate == nil {
         return
      }
      cancelled = true
      locationManager.stopUpdatingLocation()
      locationManager.delegate = nil
      _state.accept(.unknown)
   }
}

extension LocationProvider: CLLocationManagerDelegate {
   func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
      // Rely on timeout, this error is sometimes incorrect (and recoverable)
   }

   func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
      switch status {
      case .restricted:
         _state.accept(.restricted)
         stop()
      case .denied:
         _state.accept(.denied)
         stop()
      case .notDetermined:
         _state.accept(.unknown)
         cancel()
      default:
         _state.accept(.allowed)

         manager.startUpdatingLocation()
      }

      debugPrint(_state)
   }

   func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
      guard let location = locations.first else {
         return
      }
      if case .determined = _state.value {
         return
      }
      _state.accept(.determined)

      debugPrint(location)
      geocoder.reverseGeocodeLocation(location, completionHandler: { [weak self] placemark, _ in
         guard let placemark = placemark?.first, let isoCode = placemark.isoCountryCode else {
            self?._state.accept(.unknown)
            return
         }
         self?._state.accept(.identifiedCountryIso(isoCode))
         self?.stop()
      })
   }
}
