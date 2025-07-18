//
//  NavigatableState.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/7/15.
//

import Foundation

public typealias NavigatableState = DLVVM.NavigatableState

public extension DLVVM {
    protocol NavigatableState: BusinessState {
        associatedtype NavigatorEvent
    }
}
