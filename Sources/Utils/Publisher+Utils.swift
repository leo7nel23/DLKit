//
//  Publisher+Utils.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/2/17.
//

import Combine
import Observation

/// 讓 `Publisher.assign(to:)` 自動綁定 `self`
public extension Publisher where Failure == Never {
    func assign<Root: AnyObject>(to keyPath: ReferenceWritableKeyPath<Root, Output>, on root: Root) -> AnyCancellable {
        sink { [weak root] in
            root?[keyPath: keyPath] = $0
        }
    }
}
