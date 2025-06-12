//
//  Send.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/6/12.
//

@MainActor
public struct Send<Action>: Sendable {
    let send: @MainActor @Sendable (Action) -> Void

    public init(send: @escaping @MainActor @Sendable (Action) -> Void) {
        self.send = send
    }

    /// Sends an action back into the system from an effect.
    ///
    /// - Parameter action: An action.
    public func callAsFunction(_ action: Action) {
        guard !Task.isCancelled else { return }
        send(action)
    }

    /// Sends an action back into the system from an effect with animation.
    ///
    /// - Parameters:
    ///   - action: An action.
    ///   - animation: An animation.
    public func callAsFunction(_ action: Action, animation: Animation?) {
        callAsFunction(action, transaction: Transaction(animation: animation))
    }

    /// Sends an action back into the system from an effect with transaction.
    ///
    /// - Parameters:
    ///   - action: An action.
    ///   - transaction: A transaction.
    public func callAsFunction(_ action: Action, transaction: Transaction) {
        guard !Task.isCancelled else { return }
        withTransaction(transaction) {
            self(action)
        }
    }
}
