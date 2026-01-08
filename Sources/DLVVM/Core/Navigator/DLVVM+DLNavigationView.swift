//
//  NavigationView.swift
//  DLKit
//
//  Created by 賴柏宏 on 2024/12/7.
//

import Foundation
import SwiftUI

public typealias DLNavigationView = DLVVM.DLNavigationView
public typealias DLNavigatorView = DLVVM.DLNavigatorView

// MARK: - DLVVM.NavigationView

public extension DLVVM {
    struct DLNavigationView: DLView {
        @Environment(\.dismiss) var dismiss
        public typealias ReducerState = NavigationFlow

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
            navigationState: NavigationFlow
        ) {
            // Cache key for NavigatorFlow viewModel
            let navigatorFlowCacheKey = "NavigatorFlow_\(navigationState.id)"

            // Check if we have cached NavigatorFlow viewModel
            if let cachedNavigatorFlow = navigationState.rootViewModelCache[navigatorFlowCacheKey] as? DLViewModel<NavigationFlow> {
                // Reuse cached NavigatorFlow
                self.viewModel = cachedNavigatorFlow
            } else {
                // Create new NavigatorFlow and cache it
                self.viewModel = DLViewModel(
                    initialState: navigationState,
                    reducer: NavigationFeature()
                )
                navigationState.rootViewModelCache[navigatorFlowCacheKey] = self.viewModel
            }

            // Generate cache key for root viewModel based on state type and reducer type
            let rootCacheKey = "\(State.self)_\(State.R.self)"

            // Check NavigationFlow's cache for root viewModel
            if let cachedViewModel = navigationState.rootViewModelCache[rootCacheKey] as? DLViewModel<State> {
                // Check if cached viewModel's state matches current rootState
                if cachedViewModel.state !== rootState {
                    // State instance changed, need to rebind
                    let rootViewModel = viewModel.bindRootView(state: rootState, reducer: rootReducer)
                    navigationState.setUp(rootViewModel: rootViewModel)
                    navigationState.rootViewModelCache[rootCacheKey] = rootViewModel
                }
                // else: reuse cached viewModel, no action needed
            } else {
                // No cache, create new root viewModel
                let rootViewModel = viewModel.bindRootView(state: rootState, reducer: rootReducer)
                navigationState.setUp(rootViewModel: rootViewModel)
                navigationState.rootViewModelCache[rootCacheKey] = rootViewModel
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
            }
            .onChange(of: viewModel.manager.sheet, { old, new in
                guard let old, new != old else { return }
                viewModel.handleViewPopper([old.viewModel.id])
            })
            .onChange(of: viewModel.manager.fullScreenCover) { old, new in
                guard let old, new != old else { return }
                viewModel.handleViewPopper([old.viewModel.id])
            }
        }
    }

    // MARK: - DLNavigatorView

    typealias DLNavigatorView = DLNavigationView
}
