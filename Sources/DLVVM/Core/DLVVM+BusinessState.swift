//
//  State.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/2/4.
//

import Foundation
import Combine

public typealias BusinessState = DLVVM.BusinessState

public extension DLVVM {
    protocol BusinessState: AnyObject {
        associatedtype R: Reducer where R.State == Self
    }
}

nonisolated(unsafe) private var eventSubjectAssociatedKey: Void?

extension DLVVM.BusinessState {
    var eventSubject: PassthroughSubject<R.Event, Never> {
        if let subject = objc_getAssociatedObject(
            self,
            &eventSubjectAssociatedKey
        ) as? PassthroughSubject<R.Event, Never> {
            return subject
        } else {
            let subject = PassthroughSubject<R.Event, Never>()
            objc_setAssociatedObject(
                self,
                &eventSubjectAssociatedKey,
                subject,
                .OBJC_ASSOCIATION_RETAIN
            )
            return subject
        }
    }

    var eventPublisher: AnyPublisher<R.Event, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    internal func fireEvent(_ event: R.Event) {
        eventSubject.send(event)
    }
}
