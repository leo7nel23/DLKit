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
            case dismiss
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

        /// Request parent to dismiss this view
        /// 
        /// Allows any BusinessState to request dismissal from parent.
        /// Parent will automatically determine whether to dismiss sheet or fullCover.
        /// 
        /// - Returns: A procedure that requests parent dismissal
        public static var dismiss: Self {
            Self(operation: .dismiss)
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

                        case .dismiss:
                            // Dismiss requests are handled synchronously by the state
                            // They will be processed in the DLViewModel layer
                            continue
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
        /// **Note:** If dismiss is placed in the middle of a sequence, it will execute
        /// at that exact position. Procedures after dismiss may not execute if the view
        /// is dismissed. User is responsible for proper dismiss placement.
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

                    case .dismiss:
                        // Execute dismiss at user-specified position
                        // User is responsible for placing dismiss appropriately
                        // Note: This will exit the async context, but the actual dismiss
                        // will be handled by executeEffect when this procedure is processed
                        return
                    }
                }
            })
        }
    }
}
