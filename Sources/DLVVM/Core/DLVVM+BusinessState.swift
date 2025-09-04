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
    enum ViewModelRequest<R: Reducer> {
        /// Request parent to dismiss this view
        case dismiss
        /// Business logic event to be handled by parent
        case event(R.Event)
        /// Command
        case command(R.Command)
    }
}

nonisolated(unsafe) private var requestSubjectAssociatedKey: Void?

extension DLVVM.BusinessState {
    var requestSubject: PassthroughSubject<DLVVM.ViewModelRequest<R>, Never> {
        if let subject = objc_getAssociatedObject(
            self,
            &requestSubjectAssociatedKey
        ) as? PassthroughSubject<DLVVM.ViewModelRequest<R>, Never> {
            return subject
        } else {
            let subject = PassthroughSubject<DLVVM.ViewModelRequest<R>, Never>()
            objc_setAssociatedObject(
                self,
                &requestSubjectAssociatedKey,
                subject,
                .OBJC_ASSOCIATION_RETAIN
            )
            return subject
        }
    }

    var requestPublisher: AnyPublisher<DLVVM.ViewModelRequest<R>, Never> {
        requestSubject.eraseToAnyPublisher()
    }

    internal func fireRequest(_ request: DLVVM.ViewModelRequest<R>) {
        requestSubject.send(request)
    }
    
    // MARK: - Convenience methods
    
    public func fireEvent(_ event: R.Event) {
        fireRequest(.event(event))
    }
    
    internal func fireDismiss() {
        fireRequest(.dismiss)
    }

    public func dispatch(_ command: R.Command) {
        fireRequest(.command(command))
    }
}
