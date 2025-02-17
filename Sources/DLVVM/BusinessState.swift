//
//  State.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/2/4.
//

import Foundation

public typealias BusinessState = DLVVM.BusinessState

public extension DLVVM {
    @MainActor
    protocol BusinessState {
        associatedtype ViewModel: DLViewModel
    }
}
