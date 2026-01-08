//
//  DLVVM+ForEachViewModel.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/8/1.
//

import SwiftUI

public typealias ForEachViewModel = DLVVM.ForEachViewModel

public extension DLVVM {
    /// ForEachViewModel: A SwiftUI-compatible wrapper for collections
    /// 
    /// This struct works with any collection, providing the same behavior as native SwiftUI ForEach
    /// while integrating with DLVVM architecture. Supports both Identifiable elements and custom ID keyPaths.
    /// 
    /// **Primary Use Case**: Use with `viewModel.scope(stateArray:event:reducer:)` results,
    /// `Array(models.enumerated())`, or any other collection.
    /// 
    /// **Performance**: Integrates seamlessly with DLVVM's intelligent cache management
    /// and SwiftUI's diffing system for optimal performance.
    struct ForEachViewModel<Data, ID, Content>: Identifiable where Data: RandomAccessCollection, ID: Hashable {
        public let data: Data
        public let idKeyPath: KeyPath<Data.Element, ID>
        public let content: (Data.Element) -> Content

        /// Stable ID based on data content
        public let id: Int

        /// Internal initializer - use the public extensions instead
        internal init(data: Data, id: KeyPath<Data.Element, ID>, content: @escaping (Data.Element) -> Content) {
            self.data = data
            self.idKeyPath = id
            self.content = content

            // Calculate stable ID based on data content
            var hasher = Hasher()
            for element in data {
                hasher.combine(element[keyPath: id])
            }
            self.id = hasher.finalize()
        }
    }
}

// MARK: - Identifiable Collection Support

extension ForEachViewModel: View where Content: View {
    /// Renders the ForEachViewModel as a native SwiftUI ForEach
    /// 
    /// This implementation ensures full compatibility with SwiftUI's rendering
    /// and animation systems while providing DLVVM integration benefits.
    public var body: some View {
        ForEach(data, id: idKeyPath) { element in
            content(element)
        }
    }
}

// MARK: - Identifiable Collection Support

extension ForEachViewModel where Content: View, Data.Element: Identifiable, ID == Data.Element.ID {

    /// Creates a ForEachViewModel for any collection of Identifiable elements
    /// 
    /// **Primary Use Case**: Use with `parentViewModel.scope(stateArray: \.[childStates], reducer: ChildFeature())`
    /// or any other collection of Identifiable elements.
    /// 
    /// This automatically uses the element's `id` property for identity, ensuring optimal performance
    /// and seamless integration with SwiftUI's diffing system. Behaves exactly like native SwiftUI ForEach.
    /// 
    /// - Parameters:
    ///   - collection: Any collection of Identifiable elements
    ///   - content: ViewBuilder that creates views from elements
    public init(
        _ collection: Data,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.init(data: collection, id: \.id, content: content)
    }
}

// MARK: - Custom ID KeyPath Support

extension ForEachViewModel {
    /// Creates a ForEachViewModel with custom ID keyPath
    /// 
    /// **Use Cases**: 
    /// - `Array(models.enumerated())` with `id: \.offset` or `\.element.someProperty`
    /// - Collections where elements aren't Identifiable but have unique properties
    /// - Custom identity logic beyond default `.id`
    /// 
    /// Behaves exactly like native SwiftUI `ForEach(collection, id: customKeyPath) { ... }`
    /// 
    /// - Parameters:
    ///   - collection: Any collection
    ///   - id: KeyPath to the unique identifier for each element
    ///   - content: ViewBuilder that creates views from elements
    public init(
        _ collection: Data,
        id: KeyPath<Data.Element, ID>,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.init(data: collection, id: id, content: content)
    }
}
