//
//  ViewActionHandler.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/2/4.
//

import Foundation

public typealias ViewActionHandler = DLVVM.ViewActionHandler

public extension DLVVM {
    @MainActor
    protocol ViewActionHandler {
        associatedtype ViewAction

        func handleViewAction(_ action: ViewAction)
    }
}
