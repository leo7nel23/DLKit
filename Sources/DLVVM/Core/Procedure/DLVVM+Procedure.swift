//
//  Procedure.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/6/12.
//

import Foundation

public typealias Procedure = DLVVM.Procedure

// MARK: - DLVVM.Procedure

public extension DLVVM {
    struct Procedure<Action, State>: Sendable where State: BusinessState {
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

        /// 合併多個 Procedure，同時執行
        public static func merge(_ procedures: Self...) -> Self {
            Self(operation: .run { send in
                await withTaskGroup(of: Void.self) { group in
                    for procedure in procedures {
                        switch procedure.operation {
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

        /// 依序執行多個 Procedure
        public static func sequence(_ procedures: Self...) -> Self {
            Self(operation: .run { send in
                for procedure in procedures {
                    switch procedure.operation {
                    case .none:
                        continue

                    case let .run(_, operation):
                        await operation(send)
                    }
                }
            })
        }
    }
}
