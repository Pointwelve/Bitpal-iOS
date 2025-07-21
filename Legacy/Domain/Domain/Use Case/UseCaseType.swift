//
//  UseCaseType.swift
//  Domain
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

public protocol UseCaseType {
   associatedtype Repository: Actionable
   associatedtype Key
   var repository: Repository { get }
   func execute<U>(method: @escaping () -> Observable<U>) -> Observable<U>
}

extension UseCaseType where Self: Gettable, Self.Repository: Gettable, Self.Key == Self.Repository.Key {
   /// Get `Value` associated with `Key` from `Repository`.
   public func get(_ key: Key) -> Observable<Repository.Value> {
      return execute(method: { self.repository.get(key) })
   }
}

extension UseCaseType where Self: Pageable, Self.Repository: Pageable, Self.Key == Self.Repository.Key {
   /// Get next page `Value` associated with `Key` from `Repository`.
   public func nextPage(_ key: Key) -> Observable<Repository.Value> {
      return execute(method: { self.repository.nextPage(key) })
   }
}

extension UseCaseType where Self: Settable, Self.Repository: Settable, Self.Key == Self.Repository.Key {
   /// Set `Value` associated with `Key` in `Repository`.
   public func set(_ value: Repository.Value, for key: Key) -> Observable<Repository.Value> {
      return execute(method: { self.repository.set(value, for: key) })
   }
}

extension UseCaseType where Self: Peekable, Self.Repository: Peekable, Self.Key == Self.Repository.Key {
   /// Peek `Value` from `Repository` (not hitting network).
   public func peek() -> Observable<Repository.Value> {
      return execute(method: repository.peek)
   }
}

extension UseCaseType where Self: Readable, Self.Repository: Readable, Self.Key == Self.Repository.Key {
   /// Read `Value` from `Repository`.
   public func read() -> Observable<Repository.Value> {
      return execute(method: repository.read)
   }
}

extension UseCaseType where Self: Refreshable, Self.Repository: Refreshable, Self.Key == Self.Repository.Key {
   /// Read `Value` from `Repository`.
   public func refresh() -> Observable<Repository.Value> {
      return execute(method: repository.refresh)
   }
}

extension UseCaseType where Self: Writeable, Self.Repository: Writeable, Self.Key == Self.Repository.Key {
   /// Write `Value` to `Repository`.
   public func write(_ value: Repository.Value) -> Observable<Repository.Value> {
      return execute(method: { self.repository.write(value) })
   }
}

extension UseCaseType where Self: Flushable, Self.Repository: Flushable, Self.Key == Self.Repository.Key {
   /// Clear all values in `Repository`.
   public func flush() -> Observable<Void> {
      return execute(method: repository.flush)
   }
}

extension UseCaseType where Self: Updateable, Self.Repository: Updateable, Self.Key == Self.Repository.Key {
   /// Update `Value` associated with `Key` in `Repository`.
   public func update(_ key: Key) -> Observable<Repository.Value> {
      return execute(method: { self.repository.update(key) })
   }
}

extension UseCaseType where Self: Expirable, Self.Repository: Expirable,
   Self.Value == Self.Repository.Value, Self.Key == Self.Repository.Key {
   /// Check if value associated with `Key` has expired in local `Repository`.
   public func hasExpired(_ key: Key) -> Observable<Value> {
      return execute(method: { self.repository.hasExpired(key) })
   }
}

extension UseCaseType where Self: Streamable, Self.Repository: Streamable, Self.Key == Self.Repository.Key {
   /// Get `Value` associated with `Key` from `Repository`.
   public func stream(_ key: Key) -> Observable<Repository.Value> {
      return execute(method: { self.repository.stream(key) })
   }
}

extension UseCaseType where Self: Deletable, Self.Repository: Deletable, Self.Key == Self.Repository.Key {
   /// Get `Value` associated with `Key` from `Repository`.
   public func delete(_ key: Key) -> Observable<Repository.Value> {
      return execute(method: { self.repository.delete(key) })
   }
}
