//
//  DLEventPublisher.swift
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

extension DLEventPublisher where Self: DLReducibleViewModel {

    public var eventPublisher: AnyPublisher<Event, Never> { eventSubject.eraseToAnyPublisher() }

    public func fireEvent(_ event: Event) { eventSubject.send(event) }

}
