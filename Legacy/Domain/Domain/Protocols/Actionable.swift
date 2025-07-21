//
//  Actionable.swift
//  Domain
//
//  Created by Ryne Cheow on 9/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

public protocol Actionable {
   associatedtype Value
   associatedtype Key
}

/// Refers to an action that only returns a value if it exists, it will not attempt creation.
public protocol Peekable: Actionable {
   /// Peek `Value`.
   func peek() -> Observable<Value>
}

/// Refers to an action that may read a value and usually returns a value, it may come from a remote source.
public protocol Readable: Actionable {
   /// Read `Value`.
   func read() -> Observable<Value>
}

/// Refers to an action that replaces the original value with a new value, usually coming from a remote source.
public protocol Refreshable: Actionable {
   /// Refresh and read `Value`.
   func refresh() -> Observable<Value>
}

/// Refers to an action that writes a value, overwriting whatever was there.
public protocol Writeable: Actionable {
   /// Write `Value`.
   func write(_ value: Value) -> Observable<Value>
}

/// Refers to an action of validating if a particular value has expired.
public protocol Expirable: Actionable {
   /// Check if `Value` associated with `Key` has expired.
   func hasExpired(_ key: Key) -> Observable<Value>
}

/// Refers to an action of retrieving a particular value for a key, may come from remote source.
public protocol Gettable: Actionable {
   /// Get `Value` for `Key`.
   func get(_ key: Key) -> Observable<Value>
}

/// Refers to an action of extending a particular value by adding a page of information to the end.
public protocol Pageable: Actionable {
   /// Get next page for `Key`.
   func nextPage(_ key: Key) -> Observable<Value>
}

/// Refers to an action of clearing all values.
public protocol Flushable: Actionable {
   /// Flush all values.
   func flush() -> Observable<Void>
}

/// Refers to an action of writing a value associated with a particular key, overwriting whatever was there.
public protocol Settable: Actionable {
   /// Set `Value` for `Key`.
   func set(_ value: Value, for key: Key) -> Observable<Value>
}

/// Refers to an action of updating a key and returning the associated value.
public protocol Updateable: Actionable {
   /// Update `Key`.
   func update(_ key: Key) -> Observable<Value>
}

/// Stream `Value` for `Key` from `Repository`.
public protocol Streamable: Actionable {
   func stream(_ key: Key) -> Observable<Value>
}

/// Deletable `Value` for `Key` from `Repository`.
public protocol Deletable: Actionable {
   func delete(_ key: Key) -> Observable<Value>
}
