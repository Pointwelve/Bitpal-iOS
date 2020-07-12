//
//  RouteProvider.swift
//  App
//
//  Created by Li Hao Lai on 16/11/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

final class RouteProvider {
   static func open(with deeplink: String) -> RouteDef? {
      let urlComponents = deeplink.replacingOccurrences(of: "bitpal://", with: "")
         .split(separator: "/")
         .map { String($0) }

      var matchRoutes = [Route: Int]()
      var routeParams = [Route: [String: String]]()

      for route in Route.routes {
         let routeComponents = route.deeplink.split(separator: "/")

         // if total number of components not same = not match
         if routeComponents.count != urlComponents.count {
            continue
         }

         // find exact match components, not include match with parameter
         var exactMatch = 0
         var params = [String: String]()

         for (index, routeComponent) in routeComponents.enumerated() {
            // serialise parameter
            if routeComponent.contains(":") {
               params[routeComponent.replacingOccurrences(of: ":", with: "")] = urlComponents[index]
            } else if routeComponent == urlComponents[index] {
               exactMatch += 1
            } else if routeComponent != urlComponents[index] {
               continue
            }

            // finish matching, record matched route
            if routeComponent == routeComponents.last {
               matchRoutes[route] = exactMatch
               routeParams[route] = params
            }
         }
      }

      // more exact match route has more priority to process
      guard let route = (matchRoutes.max { $0.value < $1.value }?.key) else {
         return nil
      }

      return RouteDef(route: route, params: routeParams[route])
   }
}
