//
//  NavigationCapable.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/2/14.
//

import Foundation

public typealias NavigatableViewModel = NavigationCapable & ReducerViewModel
public typealias ContainedViewModel = ReducerViewModel

public typealias NavigationCapable = DLVVM.NavigationCapable

// MARK: - DLVVM.NavigationCapable

public extension DLVVM {
    @MainActor
    protocol NavigationCapable: AnyObject {
        var coordinator: CoordinatorViewModel? { get set }
    }
}
