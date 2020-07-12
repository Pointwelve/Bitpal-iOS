//
//  CacheFactory.swift
//  Domain
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

public let cacheTimeout: TimeInterval = 60 * 60

public enum CacheFactory {
   /// Values in this cache are volatile, they might be removed by either
   /// the expiry time lapsing or the maximum size being reached.
   /// - parameter memory: Memory cache to use for RAM storage.
   /// - parameter disk: Disk cache to use for storage.
   /// - parameter expiry: Time limit (in seconds) for how long values are persisted in this cache.
   /// - parameter maximumSize: Maximum number of items allowed in
   /// this cache. Oldest values will be purged - rolling cache style.
   /// - returns: New cache that links passed in caches together with volatility to values.

   public static func localOrchestratedVolatileCache<D: Cache, M: Cache>(memory: M,
                                                                         disk: D,
                                                                         expiry: TimeInterval = cacheTimeout,
                                                                         maximumSize: Int = Int.max) -> BasicCache<M.Key, M.Value>
      where M.Key == D.Key, M.Value == D.Value, M.Key: Hashable, M.Value: Modifiable {
      return BasicCache(cache: OrchestratedVolatileCache(maximumSize: maximumSize,
                                                         expiry: expiry,
                                                         memory: memory,
                                                         disk: disk))
   }

   /// Values in this cache are volatile, they might be removed by either
   /// the expiry time lapsing or the maximum size being reached.
   /// - parameter memory: Memory cache to use for RAM storage.
   /// - parameter disk: Disk cache to use for storage.
   /// - parameter network: Network cache to use for getting values
   /// from the server when there are none on disk or in memory.
   /// - parameter expiry: Time limit (in seconds) for how long values are persisted in this cache.
   /// - parameter maximumSize: Maximum number of items allowed in
   /// this cache. Oldest values will be purged - rolling cache style.
   /// - returns: New cache that links passed in caches together with volatility to values.

   public static func orchestratedVolatileCache<D: Cache, N: Cache, M: Cache>(memory: M,
                                                                              disk: D,
                                                                              network: N,
                                                                              expiry: TimeInterval = cacheTimeout,
                                                                              maximumSize: Int = Int.max) -> BasicCache<N.Key, N.Value>
      where M.Key == D.Key, M.Value == D.Value, N.Key == D.Key,
      N.Value == D.Value, M.Key: Hashable, M.Value: Modifiable {
      return OrchestratedVolatileCache(maximumSize: maximumSize,
                                       expiry: expiry,
                                       memory: memory,
                                       disk: disk).compose(network)
   }

   /// Instantiate a cache that optionally interacts with the disk storage or
   /// the network, values are persisted until manually removed.
   /// - parameter cache: Secondary cache to use delegate to.
   /// - returns: New cache that links passed in caches together.
   public static func memoryCache<K: Hashable, V, C: Cache>
   (combinedWith cache: C) -> BasicCache<K, V>
      where C.Key == K, C.Value == V {
      return MemoryCache<K, V>() + cache
   }

   /// Instantiate a cache that optionally interacts with the disk storage
   /// or the network, values are persisted until manually removed.
   /// - parameter disk: Disk cache to use for storage.
   /// - parameter network: Network cache to use for getting values from
   /// the server when there are none on disk or in memory.
   /// - returns: New cache that links passed in caches together.
   public static func memoryCache<K: Hashable, V, C: Cache, F: Cache>
   (combinedWithDisk disk: C, andNetwork network: F) -> BasicCache<K, V>
      where C.Key == K, F.Key == K, C.Value == V, F.Value == V {
      return MemoryCache<K, V>() + disk + network
   }
}
