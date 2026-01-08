//
//  DLVVM+Cache.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/8/2.
//

import Foundation

// MARK: - Internal Cache Containers

extension DLVVM {
    /// Storage for cached view models with weak references to prevent retain cycles
    class ArrayViewModels {
        fileprivate var viewModels: [String: AnyObject] = [:]

        func setObject(_ object: AnyObject?, forKey key: String) {
            viewModels[key] = object
        }

        func object(forKey key: String) -> AnyObject? {
            viewModels[key]
        }
    }

    /// Container to cache array instances with content comparison for SwiftUI stability (legacy support)
    class ArrayContainer<ChildState: BusinessState & Identifiable> {
        let viewModels: [DLViewModel<ChildState>]
        private let contentSnapshot: [ChildState.ID]

        init(viewModels: [DLViewModel<ChildState>], contentSnapshot: [ChildState.ID]) {
            self.viewModels = viewModels
            self.contentSnapshot = contentSnapshot
        }

        /// Check if the current content matches the cached content
        func hasEqualContent(to states: [ChildState]) -> Bool {
            let newSnapshot = states.map { $0.id }
            return contentSnapshot == newSnapshot
        }
    }

    /// Container to cache array instances with content comparison for SwiftUI stability
    class CachedViewModelArray<ChildState: BusinessState & Identifiable> {
        let viewModels: [DLViewModel<ChildState>]
        private let contentSnapshot: [ChildState.ID]

        init(viewModels: [DLViewModel<ChildState>], contentSnapshot: IdentifiedArray<ChildState>) {
            self.viewModels = viewModels
            self.contentSnapshot = contentSnapshot.map { $0.id }
        }

        /// Check if the current content matches the cached content
        func hasEqualContent(to identifiedArray: IdentifiedArray<ChildState>) -> Bool {
            let newSnapshot = identifiedArray.map { $0.id }
            return contentSnapshot == newSnapshot
        }
    }
}
