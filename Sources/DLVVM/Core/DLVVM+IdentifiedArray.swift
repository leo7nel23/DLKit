//
//  DLVVM+IdentifiedArray.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/8/2.
//

import Foundation

// MARK: - Public Type Aliases

public typealias IdentifiedArray = DLVVM.IdentifiedArray
public typealias IdentifiedArrayOf<Element: BusinessState & Identifiable> = DLVVM.IdentifiedArray<Element>

// MARK: - DLVVM.IdentifiedArray

public extension DLVVM {
    /// Type-safe identified array for DLVVM with full Array-like functionality
    /// 
    /// This struct provides a complete Array replacement for collections of identified elements,
    /// ensuring type safety for scope operations while maintaining familiar Array semantics.
    struct IdentifiedArray<Element: BusinessState & Identifiable>: 
        Collection, MutableCollection, RangeReplaceableCollection, ExpressibleByArrayLiteral {
        
        public typealias Index = Array<Element>.Index
        public typealias Iterator = Array<Element>.Iterator
        public typealias ArrayLiteralElement = Element
        
        private var elements: [Element]
        
        // MARK: - Initialization
        
        /// Creates an empty identified array
        public init() {
            self.elements = []
        }
        
        /// Creates an identified array from a regular array
        public init(_ elements: [Element]) {
            self.elements = elements
        }
        
        /// Creates an identified array from array literal
        public init(arrayLiteral elements: Element...) {
            self.elements = elements
        }
        
        /// Creates an identified array from any sequence
        public init<S: Sequence>(_ sequence: S) where S.Element == Element {
            self.elements = Array(sequence)
        }
        
        /// Static factory method for more intuitive array conversion
        public static func from<S: Sequence>(_ sequence: S) -> IdentifiedArray<Element> where S.Element == Element {
            return IdentifiedArray(sequence)
        }
        
        // MARK: - Collection Conformance
        
        public var startIndex: Index { elements.startIndex }
        public var endIndex: Index { elements.endIndex }
        
        public subscript(position: Index) -> Element {
            get { elements[position] }
            set { elements[position] = newValue }
        }
        
        public func index(after i: Index) -> Index {
            elements.index(after: i)
        }
        
        public func makeIterator() -> Iterator {
            elements.makeIterator()
        }
        
        // MARK: - RangeReplaceableCollection
        
        public mutating func replaceSubrange<C>(_ subrange: Range<Index>, with newElements: C) 
        where C: Collection, C.Element == Element {
            elements.replaceSubrange(subrange, with: newElements)
        }
        
        // MARK: - Array-like Operations
        
        /// Adds an element to the end of the array
        public mutating func append(_ element: Element) {
            elements.append(element)
        }
        
        /// Adds the elements of a sequence to the end of the array
        public mutating func append<S: Sequence>(contentsOf newElements: S) where S.Element == Element {
            elements.append(contentsOf: newElements)
        }
        
        /// Inserts an element at the specified position
        public mutating func insert(_ element: Element, at index: Index) {
            elements.insert(element, at: index)
        }
        
        /// Removes and returns the element at the specified position
        @discardableResult
        public mutating func remove(at index: Index) -> Element {
            return elements.remove(at: index)
        }
        
        /// Removes all elements from the array
        public mutating func removeAll(keepingCapacity: Bool = false) {
            elements.removeAll(keepingCapacity: keepingCapacity)
        }
        
        // MARK: - ID-based Operations
        
        /// Access element by ID
        public subscript(id id: Element.ID) -> Element? {
            get {
                elements.first { $0.id == id }
            }
            set {
                if let newValue = newValue {
                    if let index = elements.firstIndex(where: { $0.id == id }) {
                        elements[index] = newValue
                    } else {
                        elements.append(newValue)
                    }
                } else {
                    elements.removeAll { $0.id == id }
                }
            }
        }
        
        /// Removes and returns the element with the specified ID
        @discardableResult
        public mutating func remove(id: Element.ID) -> Element? {
            guard let index = elements.firstIndex(where: { $0.id == id }) else { return nil }
            return elements.remove(at: index)
        }
        
        /// Checks if an element with the specified ID exists
        public func contains(id: Element.ID) -> Bool {
            elements.contains { $0.id == id }
        }
        
        // MARK: - Convenience Properties
        
        public var count: Int { elements.count }
        public var isEmpty: Bool { elements.isEmpty }
        public var first: Element? { elements.first }
        public var last: Element? { elements.last }
        
        // MARK: - Internal for Caching
        
        /// Check if the current content matches another identified array
        internal func hasEqualContent(to other: IdentifiedArray<Element>) -> Bool {
            let thisSnapshot = elements.map { $0.id }
            let otherSnapshot = other.elements.map { $0.id }
            return thisSnapshot == otherSnapshot
        }
        
        /// Check if the current content matches a plain array
        internal func hasEqualContent(to states: [Element]) -> Bool {
            let thisSnapshot = elements.map { $0.id }
            let otherSnapshot = states.map { $0.id }
            return thisSnapshot == otherSnapshot
        }
    }
}