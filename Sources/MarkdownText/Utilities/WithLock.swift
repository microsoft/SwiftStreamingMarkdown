//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation

@propertyWrapper
final class WithLock<Value> {
  private var value: Value
  private let lock = NSRecursiveLock()

  init(wrappedValue: Value) {
    self.value = wrappedValue
  }

  var wrappedValue: Value {
    get {
      lock.lock()
      defer { lock.unlock() }
      return value
    }
    set {
      lock.lock()
      value = newValue
      lock.unlock()
    }
  }

  var projectedValue: WithLock<Value> { self }

  func read<T>(closure: (Value) -> T) -> T {
    lock.lock()
    defer { lock.unlock() }
    return closure(value)
  }

  func read<T>(_ closure: (Value) -> T) -> T {
    read(closure: closure)
  }

  @discardableResult
  func mutate<T>(_ closure: (inout Value) -> T) -> T {
    lock.lock()
    defer { lock.unlock() }
    return closure(&value)
  }
}
