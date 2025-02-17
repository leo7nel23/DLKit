//
//  Observation+Utils.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/2/17.
//

import Combine
import Foundation
import Observation

/// 讓 `@Observable` 屬性可以轉換為 `ObservationPublisher`
struct ObservationPublisher<Object: Observable, Value>: Publisher {
    typealias Output = Value
    typealias Failure = Never

    private let object: Object
    private let keyPath: KeyPath<Object, Value>

    init(object: Object, keyPath: KeyPath<Object, Value>) {
        self.object = object
        self.keyPath = keyPath
    }

    /// `Combine` 訂閱者的核心實作
    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = ObservationSubscription(subscriber: subscriber, object: object, keyPath: keyPath)
        subscriber.receive(subscription: subscription)
    }
}

final class ObservationSubscription<Object: Observable, Value, S: Subscriber>: @unchecked Sendable, Subscription where S.Input == Value, S.Failure == Never {

    private var subscriber: S?
    private let object: Object
    private let keyPath: KeyPath<Object, Value>

    init(subscriber: S, object: Object, keyPath: KeyPath<Object, Value>) {
        self.subscriber = subscriber
        self.object = object
        self.keyPath = keyPath
        startObserving()
    }

    func request(_ demand: Subscribers.Demand) {
        // 由於是主動推送資料，這裡不需要額外邏輯
    }

    func cancel() {
        subscriber = nil
    }

    private func startObserving() {
        withObservationTracking {
            let newValue = object[keyPath: keyPath]
            _ = subscriber?.receive(newValue)
        } onChange: { [weak self] in
//            guard let self else { return }
            DispatchQueue.main.async {
                self?.startObserving()
            }
        }
    }
}

public extension Observable {
    func publisher<Value>(_ keyPath: KeyPath<Self, Value>) -> AnyPublisher<Value, Never> {
        return ObservationPublisher(object: self, keyPath: keyPath)
            .eraseToAnyPublisher()
    }
}
