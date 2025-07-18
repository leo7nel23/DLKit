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

        /// No side effects
        public static var none: Self {
            Self(operation: .none)
        }

        /// Execute asynchronous task with error handling
        /// 
        /// Creates a procedure that runs an asynchronous operation with automatic
        /// error handling. Cancellation errors are silently ignored.
        /// 
        /// - Parameters:
        ///   - priority: Optional task priority for execution
        ///   - operation: The async operation to perform
        ///   - handler: Optional error handler for non-cancellation errors
        /// - Returns: A procedure that executes the async operation
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

        /// Merge multiple Procedures and execute concurrently
        /// 
        /// Creates a procedure that runs multiple procedures simultaneously using
        /// structured concurrency (TaskGroup). All procedures execute in parallel.
        /// 
        /// - Parameter procedures: Variable number of procedures to merge
        /// - Returns: A procedure that executes all input procedures concurrently
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

        /// Execute multiple Procedures sequentially
        /// 
        /// Creates a procedure that runs multiple procedures one after another in order.
        /// Each procedure completes before the next one begins.
        /// 
        /// - Parameter procedures: Variable number of procedures to execute in sequence
        /// - Returns: A procedure that executes all input procedures sequentially
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
