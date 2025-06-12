//
//  DLReducer.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/2/4.
//

import Foundation

public typealias BusinessReducer = DLVVM.BusinessReducer

public extension DLVVM {
    protocol BusinessReducer {
        associatedtype State: BusinessState
        associatedtype Action

        static func reduce(into state: inout State, action: Action) -> Effect<Action>
    }
    
}

public extension DLVVM.BusinessReducer where State.ViewModel: (DLViewModel & EventPublisher) {
    static func fireEvent(_ event: State.ViewModel.Event, with state: State) {
        state.eventSubject.send(event)
    }
}
