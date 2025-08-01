//
//  DLVVM+ForEachViewModel.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/8/1.
//

import SwiftUI

public typealias ForEachViewModel = DLVVM.ForEachViewModel

public extension DLVVM {
    /// ForEachViewModel: A SwiftUI-compatible wrapper for iterating over collections
    /// 
    /// This struct mimics SwiftUI's native ForEach but integrates seamlessly with DLVVM architecture.
    /// For optimal performance and memory management, use with Identifiable collections.
    /// 
    /// **Performance Note**: When working with dynamic arrays (content that changes over time),
    /// ensure your data elements conform to Identifiable for efficient SwiftUI diffing and
    /// proper integration with DLVVM's intelligent cache management system.
    struct ForEachViewModel<Data, ID, Content> where Data: RandomAccessCollection, ID: Hashable {
        public let data: Data
        public let idKeyPath: KeyPath<Data.Element, ID>
        public let content: (Data.Element) -> Content
        
        /// Basic initializer requiring explicit ID keyPath
        /// 
        /// **Recommendation**: Consider using the Identifiable-based initializers for better performance
        /// 
        /// - Parameters:
        ///   - data: The collection to iterate over
        ///   - id: KeyPath to the unique identifier for each element
        ///   - content: Closure that creates views from data elements
        public init(data: Data, id: KeyPath<Data.Element, ID>, content: @escaping (Data.Element) -> Content) {
            self.data = data
            self.idKeyPath = id
            self.content = content
        }
    }
}

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

// MARK: - Public Initializers

extension ForEachViewModel where Content: View {
    /// Creates an instance that uniquely identifies and creates views across
    /// updates based on the provided key path to the underlying data's identifier.
    ///
    /// **Identity Stability Warning**: The `id` of a data element should remain stable.
    /// If the `id` changes, SwiftUI will treat it as a completely new element, causing
    /// the view to lose its current state and animations.
    ///
    /// **Performance Recommendation**: For dynamic arrays, prefer using Identifiable
    /// collections with the convenience initializer for optimal performance.
    ///
    /// - Parameters:
    ///   - data: The data that the ``ForEachViewModel`` instance uses to create views
    ///     dynamically.
    ///   - id: The key path to the provided data's identifier.
    ///   - content: The view builder that creates views dynamically.
    public init(_ data: Data, id: KeyPath<Data.Element, ID>, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.idKeyPath = id
        self.content = content
    }
}

// MARK: - Identifiable Element Support

extension ForEachViewModel where Content: View, Data.Element: Identifiable, ID == Data.Element.ID {
    /// Creates an instance that uniquely identifies and creates views across
    /// updates based on the identity of the underlying data element.
    ///
    /// **Recommended Usage**: This is the preferred initializer for arrays of Identifiable elements.
    /// It ensures optimal performance by leveraging SwiftUI's built-in diffing algorithm.
    ///
    /// - Parameters:
    ///   - data: The identifiable data that the ``ForEachViewModel`` instance uses to create
    ///     views dynamically.
    ///   - content: The view builder that creates views dynamically.
    public init(_ data: Data, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.idKeyPath = \.id
        self.content = content
    }
}

// MARK: - DLViewModel Array Support

extension ForEachViewModel where Content: View, Data.Element: DLViewModelProtocol {
    /// Creates a ForEachViewModel for DLViewModel arrays where the state conforms to Identifiable
    /// 
    /// This convenience initializer automatically uses the state's `id` property for identity,
    /// ensuring optimal performance and cache management for dynamic arrays.
    /// 
    /// **Requirements**: The ViewModel's State must conform to Identifiable for proper SwiftUI diffing
    /// 
    /// - Parameters:
    ///   - viewModels: Array of DLViewModels with Identifiable states
    ///   - content: ViewBuilder that creates views from ViewModels
    public init(
        _ viewModels: Data,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) where Data.Element.State: Identifiable, ID == Data.Element.State.ID {
        self.data = viewModels
        // 使用 state.id 確保與 DLVVM 快取系統一致
        self.idKeyPath = \Data.Element.state.id
        self.content = content
    }
    
    /// Creates a ForEachViewModel for DLViewModel arrays using custom ID keyPath
    /// 
    /// Use this when you need custom identity logic beyond state.id.
    /// 
    /// - Parameters:
    ///   - viewModels: Array of DLViewModels
    ///   - id: KeyPath to the identity property
    ///   - content: ViewBuilder that creates views from ViewModels
    public init(
        _ viewModels: Data,
        id: KeyPath<Data.Element, ID>,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = viewModels
        self.idKeyPath = id
        self.content = content
    }
}
