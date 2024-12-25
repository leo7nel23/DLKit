//
//  Array+Utils.swift
//  Investor
//
//  Created by 賴柏宏 on 2024/8/15.
//  Copyright © 2024 Devin Lai. All rights reserved.
//

import Foundation

public extension Array where Element == Double {
  func sum() -> Element {
    return self.reduce(0, +)
  }

  func average() -> Element {
    return self.sum() / Element(self.count)
  }

  func std() -> Element {
    return sqrt(variance())
  }

  func variance() -> Element {
    let mean = self.average()
    let v = self.reduce(0, { $0 + ($1-mean)*($1-mean) })
    return v / (Element(self.count) - 1)
  }

  func covariancePopulation(with y: [Double]) -> Double? {
    let xCount = Double(self.count)
    let yCount = Double(y.count)

    if xCount == 0 { return nil }
    if xCount != yCount { return nil }

    let xMean = self.average()
    let yMean = y.average()

    var sum:Double = 0

    for (index, xElement) in self.enumerated() {
      let yElement = y[index]

      sum += (xElement - xMean) * (yElement - yMean)
    }

    return sum / (xCount - 1)
  }
}

public extension Array {
  func pairwise<T>( operation: (Element, Element) -> T) -> [T] {
      guard count > 1 else { return [] }
      var results: [T] = []
      for i in 0..<(count - 1) {
          let result = operation(self[i], self[i + 1])
          results.append(result)
      }
      return results
  }
}
