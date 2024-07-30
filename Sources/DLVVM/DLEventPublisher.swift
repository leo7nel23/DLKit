//
//  File.swift
//  
//
//  Created by 賴柏宏 on 2024/7/30.
//

import Foundation
import Combine

public typealias DLEventPublisher = DevinLaiEventPublisher
public protocol DevinLaiEventPublisher {

    associatedtype Event

    var eventPublisher: AnyPublisher<Event, Never> { get }
}

extension DevinLaiEventPublisher where Self: DLPropertiesViewModel {

    public var eventPublisher: AnyPublisher<Event, Never> { properties.eventPublisher }

    public func fireEvent(_ event: Event) { properties.fireEvent(event) }

}
