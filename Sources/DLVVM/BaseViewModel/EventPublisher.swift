//
//  EventPublisher.swift
//
//
//  Created by 賴柏宏 on 2024/7/30.
//

import Foundation
import Combine

public typealias EventPublisher = DLVVM.EventPublisher

public extension DLVVM {
    @MainActor
    protocol EventPublisher {
        associatedtype Event
        var eventPublisher: AnyPublisher<Event, Never> { get }
    }
}

public extension EventPublisher where Self: DLViewModel {

    var eventPublisher: AnyPublisher<Event, Never> { eventSubject.eraseToAnyPublisher() }

    func fireEvent(_ event: Event) { eventSubject.send(event) }

}
