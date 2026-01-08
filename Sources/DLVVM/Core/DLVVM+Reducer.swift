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
        associatedtype Event = Void
        associatedtype Command = Void

        func reduce(into state: State, action: Action) -> Procedure<Action, State>
        func reduce(into state: State, command: Command) -> Procedure<Action, State>
    }
}

public extension DLVVM.Reducer where Command == Void {
    func reduce(into state: State, command: Command) -> Procedure<Action, State> {
        .none
    }
}

public extension DLVVM.Reducer where State.R == Self {
    func fireEvent(_ event: Event, with state: State) {
        state.fireEvent(event)
    }
}

public extension DLVVM.Reducer where State.R.Action == Void {
    func reduce(into state: State, action: Action) -> Procedure<Action, State> { .none }
}

public extension DLVVM.Reducer where State.R == Self, State: NavigatableState {
    func route<ChildState: BusinessState>(
        childState keyPath: WritableKeyPath<State, ChildState?>,
        to mapper: ((ChildState.R.Event) -> Action)? = nil,
        reducer: ChildState.R,
        routeStyle: RouteStyle,
        with state: State
    ) {
        state.routeSubject.send(
            AnyNextStateKeyPath(
                keyPath: keyPath,
                eventMapper: mapper ?? { _ in nil },
                reducer: reducer,
                routeStyle: routeStyle
            )
            .eraseToNextKeyPath()
        )
    }

    func route<ChildState: NavigationFlow, RootState: NavigatableState, Output>(
        childState keyPath: WritableKeyPath<State, ChildState?>,
        container: AnyNavigatableStateContainer<RootState>,
        to mapper: @escaping (Output) -> Action?,
        routeStyle: RouteStyle,
        with state: State
    ) {
        state.routeSubject.send(
            NavigationStateKeyPath(
                keyPath: keyPath,
                eventMapper: {
                    if let action = $0 as? Output {
                        mapper(action)
                    } else {
                        nil
                    }
                },
                rootState: container.state,
                rootReducer: container.reducer,
                routeStyle: routeStyle
            )
            .eraseToNextKeyPath()
        )
    }

    func route<ChildState: NavigationFlow, RootState: NavigatableState>(
        childState keyPath: WritableKeyPath<State, ChildState?>,
        container: AnyNavigatableStateContainer<RootState>,
        routeStyle: RouteStyle,
        with state: State
    ) {
        state.routeSubject.send(
            NavigationStateKeyPath(
                keyPath: keyPath,
                eventMapper: { _ in nil },
                rootState: container.state,
                rootReducer: container.reducer,
                routeStyle: routeStyle
            )
            .eraseToNextKeyPath()
        )
    }

    func dismiss(with state: State) {
        state.dismiss(.dismiss)
    }

    func dismissSheet(with state: State) {
        state.dismiss(.dismissSheet)
    }

    func dismissFullCover(with state: State) {
        state.dismiss(.dismissFullCover)
    }

    func pop(with state: State) {
        state.dismiss(.pop)
    }

    func fireNavigatorEvent(_ event: State.NavigatorEvent, with state: State) {
        state.fireNavigatorEvent(event)
    }
}

public struct AnyNavigatableStateContainer<State: NavigatableState> {
    public let state: State
    public let reducer: State.R

    public init(state: State, reducer: State.R) {
        self.state = state
        self.reducer = reducer
    }
}
