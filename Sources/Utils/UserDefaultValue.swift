//
//  UserDefaultValue.swift
//
//
//  Created by 賴柏宏 on 2024/12/6.
//

import Foundation

@propertyWrapper
public struct UserDefaultValue<Value> {
  let userDefault = UserDefaults.standard
  let key: String
  let defaultValue: Value

  public var wrappedValue: Value {
    get {
      userDefault.value(forKey: key) as? Value ?? defaultValue
    }

    set {
      userDefault.setValue(newValue, forKey: key)
    }
  }

  public init(key: String, defaultValue: Value) {
    self.key = key
    self.defaultValue = defaultValue
  }
}
