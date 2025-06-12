//
//  Effect.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/6/12.
//

import Foundation

public typealias Effect = DLVVM.Effect

// MARK: - DLVVM.Effect

public extension DLVVM {
    struct Effect<Action>: Sendable {
        @usableFromInline
        enum Operation: Sendable {
            case none
            case run(TaskPriority? = nil, @Sendable (_ send: Send<Action>) async -> Void)
        }

        @usableFromInline
        let operation: Operation

        @usableFromInline
        init(operation: Operation) {
            self.operation = operation
        }

        /// 沒有副作用
        public static var none: Self {
            Self(operation: .none)
        }

        /// 執行非同步任務
        public static func run(
            priority: TaskPriority? = nil,
            operation: @escaping @Sendable (_ send: Send<Action>) async throws -> Void,
            catch handler: (@Sendable (_ error: any Error, _ send: Send<Action>) async -> Void)? = nil,
            fileID _: StaticString = #fileID,
            filePath _: StaticString = #filePath,
            line _: UInt = #line,
            column _: UInt = #column
        ) -> Self {
            Self(
                operation: .run(priority) { send in
                    do {
                        try await operation(send)
                    } catch is CancellationError {
                        return
                    } catch {
                        guard let handler else { return }
                        await handler(error, send)
                    }
                }
            )
        }

        /// 合併多個 Effect，同時執行
        public static func merge(_ effects: Self...) -> Self {
            Self(operation: .run { send in
                await withTaskGroup(of: Void.self) { group in
                    for effect in effects {
                        switch effect.operation {
                        case .none:
                            continue
                        case let .run(priority, operation):
                            group.addTask(priority: priority) {
                                await operation(send)
                            }
                        }
                    }
                }
            })
        }

        /// 依序執行多個 Effect
        public static func sequence(_ effects: Self...) -> Self {
            Self(operation: .run { send in
                for effect in effects {
                    switch effect.operation {
                    case .none:
                        continue

                    case let .run(_, operation):
                        await operation(send)
                    }
                }
            })
        }

        /// 串接兩個 Effect
        public static func concatenate(_ first: Self, _ second: Self) -> Self {
            sequence(first, second)
        }

        /// 使用運算子串接兩個 Effect
        public static func + (lhs: Self, rhs: Self) -> Self {
            concatenate(lhs, rhs)
        }
    }
}
