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

extension DLVVM {
    /// Request type for communication between child and parent ViewModels
    enum ViewModelRequest<Event> {
        /// Request parent to dismiss this view
        case dismiss
        /// Business logic event to be handled by parent
        case event(Event)
    }
}

nonisolated(unsafe) private var requestSubjectAssociatedKey: Void?

extension DLVVM.BusinessState {
    var requestSubject: PassthroughSubject<DLVVM.ViewModelRequest<R.Event>, Never> {
        if let subject = objc_getAssociatedObject(
            self,
            &requestSubjectAssociatedKey
        ) as? PassthroughSubject<DLVVM.ViewModelRequest<R.Event>, Never> {
            return subject
        } else {
            let subject = PassthroughSubject<DLVVM.ViewModelRequest<R.Event>, Never>()
            objc_setAssociatedObject(
                self,
                &requestSubjectAssociatedKey,
                subject,
                .OBJC_ASSOCIATION_RETAIN
            )
            return subject
        }
    }

    var requestPublisher: AnyPublisher<DLVVM.ViewModelRequest<R.Event>, Never> {
        requestSubject.eraseToAnyPublisher()
    }

    internal func fireRequest(_ request: DLVVM.ViewModelRequest<R.Event>) {
        requestSubject.send(request)
    }
    
    // MARK: - Convenience methods
    
    internal func fireEvent(_ event: R.Event) {
        fireRequest(.event(event))
    }
    
    internal func fireDismiss() {
        fireRequest(.dismiss)
    }
}
