//
//  UserDefaultValue.swift
//
//
//  Created by 賴柏宏 on 2024/12/6.
//

import Foundation

@propertyWrapper
public struct UserDefaultValue<Value> {
  let userDefault: UserDefaults
  let key: String
  let defaultValue: Value

  public init(userDefault: UserDefaults = .standard, key: String, defaultValue: Value) {
    self.userDefault = userDefault
    self.key = key
    self.defaultValue = defaultValue
  }

  public var wrappedValue: Value {
    get {
      userDefault.value(forKey: key) as? Value ?? defaultValue
    }

    set {
      userDefault.setValue(newValue, forKey: key)
    }
  }
}
