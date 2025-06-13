//
//  DLReducer.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/2/4.
//

import Foundation

public typealias Reducer = DLVVM.Reducer

public extension DLVVM {
    protocol Reducer<State, Action, Event> where State: BusinessState {
        associatedtype State
        associatedtype Action
        associatedtype Event

        func reduce(into state: State, action: Action) -> Effect<Action>
    }
    
}

public extension DLVVM.Reducer where State.R == Self {
    func fireEvent(_ event: Event, with state: State) {
        state.eventSubject.send(event)
    }
}
