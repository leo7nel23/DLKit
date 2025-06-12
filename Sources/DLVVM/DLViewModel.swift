//
//  DLViewModel.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/2/4.
//

import Foundation
import Combine

public typealias DLViewModel = DLVVM.DLViewModel

public extension DLVVM {
    @MainActor
    protocol DLViewModel: AnyObject {
        associatedtype State: BusinessState where State.ViewModel == Self
        associatedtype Reducer: BusinessReducer where Reducer.ViewModel == Self

        var state: State { get set }

        var subscriptions: Set<AnyCancellable> { get set }
    }
}

public extension DLViewModel {

    func reduce(_ action: Reducer.Action) {
        Reducer.reduce(state: &state, action: action)
    }

    func makeSubViewModel<T: DLViewModel & EventPublisher>(
        _ maker: () -> T,
        convertAction: @escaping (T.Event) -> Reducer.Action?
    ) -> T {
        let viewModel: T = maker()

        viewModel.eventPublisher
            .sink { [weak self] event in
                guard let self,
                      let action = convertAction(event)
                else { return }
                self.reduce(action)
            }
            .store(in: &subscriptions)

        return viewModel
    }
}

nonisolated(unsafe) fileprivate var eventSubjectAssociatedKey: Void?

extension DLViewModel where Self: EventPublisher {

    var eventSubject: PassthroughSubject<Event, Never> {
        if let subject = objc_getAssociatedObject(self, &eventSubjectAssociatedKey) as? PassthroughSubject<Event, Never> {
            return subject
        } else {
            let subject = PassthroughSubject<Event, Never>()
            objc_setAssociatedObject(self, &eventSubjectAssociatedKey, subject, .OBJC_ASSOCIATION_RETAIN)
            return subject
        }
    }

    var eventPublisher: AnyPublisher<Event, Never> {
        eventSubject.eraseToAnyPublisher()
    }
}
