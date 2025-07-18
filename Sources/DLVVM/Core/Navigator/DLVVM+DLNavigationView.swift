//
//  NavigationView.swift
//  DLKit
//
//  Created by 賴柏宏 on 2024/12/7.
//

import Foundation
import SwiftUI

public typealias DLNavigationView = DLVVM.DLNavigationView

// MARK: - DLVVM.NavigationView

public extension DLVVM {
    struct DLNavigationView: DLView {
        @Environment(\.dismiss) var dismiss
        public typealias ReducerState = NavigationState

        @State public var viewModel: ViewModel

        public init(viewModel: ViewModel) {
            self.viewModel = viewModel
            guard viewModel.rootInfo != nil else {
                fatalError("Must bind Root!!")
            }
        }

        public init<State: NavigatableState>(
            rootState: State,
            rootReducer: State.R,
            navigationState: NavigationState
        ) {
            self.viewModel = DLViewModel(
                initialState: navigationState,
                reducer: NavigationReducer()
            )
            if navigationState.rootInfo == nil {
                let rootViewModel = viewModel.bindRootView(state: rootState, reducer: rootReducer)
                navigationState.setUp(rootViewModel: rootViewModel)
            }
        }

        public var body: some View {
            NavigationStack(
                path: $viewModel.manager.path
            ) {
                viewModel.state.buildView(for: viewModel.manager.root)
                    .navigationDestination(for: NavigatorInfo.self) {
                        viewModel.state.buildView(for: $0)
                    }
            }
            .sheet(item: $viewModel.manager.sheet) {
                viewModel.state.buildView(for: $0)
            }
            .fullScreenCover(item: $viewModel.manager.fullScreenCover) {
                viewModel.state.buildView(for: $0)
            }
            .onReceive(viewModel.manager.onDismissSubject) { _ in
                dismiss()
            }
            .alert(
                viewModel.manager.alert?.title ?? "",
                isPresented: Binding<Bool>(
                    get: { viewModel.manager.alert != nil },
                    set: { _ in viewModel.manager.alert = nil }
                ),
                presenting: viewModel.manager.alert,
                actions: {
                    AnyView($0.viewBuilder())
                },
                message: {
                    Text($0.message)
                }
            )
            .onChange(of: viewModel.manager.path) { old, new in
                let removed = old.filter { !new.contains($0) }
                let removedIds = removed.map { $0.viewModel.id }
                guard !removedIds.isEmpty else { return }
                viewModel.handleViewPopper(removedIds)
//                print(removed.first?.viewModel.)
            }
            .onChange(of: viewModel.manager.fullScreenCover) { old, new in
                guard let old, new != old else { return }
                viewModel.handleViewPopper([old.viewModel.id])
            }
        }
    }
}
