//
//  Sequence+Utils.swift
//  DLKit
//
//  Created by 賴柏宏 on 2024/12/23.
//

import Foundation

public extension Sequence {
    func asyncMap<T>(
        _ transform: (Element) async throws -> T
    ) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            try await values.append(transform(element))
        }

        return values
    }

    func asyncCompactMap<T>(
        _ transform: (Element) async throws -> T?
    ) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            if let transformedValue = try await transform(element) {
                values.append(transformedValue)
            }
        }

        return values
    }
}
