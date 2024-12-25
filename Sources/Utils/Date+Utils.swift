//
//  Date+Utils.swift
//  DLKit
//
//  Created by 賴柏宏 on 2024/12/23.
//

import Foundation

public extension Date {
  var year: Int {
    Calendar.current.component(.year, from: self)
  }

  var month: Int {
    Calendar.current.component(.month, from: self)
  }

  var day: Int {
    Calendar.current.component(.day, from: self)
  }
}
