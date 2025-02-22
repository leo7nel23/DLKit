//
//  CoordinatorCallback.swift
//  DLKit
//
//  Created by 賴柏宏 on 2024/12/11.
//

import Foundation

public typealias CoordinatorCallback = DLVVM.CoordinatorCallback

// MARK: - DLVVM.CoordinatorCallback

public extension DLVVM {
    struct CoordinatorCallback<T>: Hashable, Identifiable {
        public let id: String = UUID().uuidString

        public let run: (T) -> Void

        public init(run: @escaping (T) -> Void) {
            self.run = run
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id
        }

        public func eraseToAnyCoordinatorCallback() -> CoordinatorCallback<Any?> {
            CoordinatorCallback<Any?> {
                guard let result = $0 as? T else { return }
                run(result)
            }
        }
    }
}
