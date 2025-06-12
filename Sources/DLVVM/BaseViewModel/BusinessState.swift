//
//  State.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/2/4.
//

import Foundation

public typealias BusinessState = DLVVM.BusinessState

public extension DLVVM {
    protocol BusinessState: AnyObject {
        associatedtype ViewModel: DLViewModel
    }
}

nonisolated(unsafe) private var eventSubjectAssociatedKey: Void?

extension DLVVM.BusinessState where ViewModel: EventPublisher {
    var eventSubject: PassthroughSubject<ViewModel.Event, Never> {
        if let subject = objc_getAssociatedObject(
            self,
            &eventSubjectAssociatedKey
        ) as? PassthroughSubject<ViewModel.Event, Never> {
            return subject
        } else {
            let subject = PassthroughSubject<ViewModel.Event, Never>()
            objc_setAssociatedObject(
                self,
                &eventSubjectAssociatedKey,
                subject,
                .OBJC_ASSOCIATION_RETAIN
            )
            return subject
        }
    }

    var eventPublisher: AnyPublisher<ViewModel.Event, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    internal func fireEvent(_ event: ViewModel.Event) {
        eventSubject.send(event)
    }
}
