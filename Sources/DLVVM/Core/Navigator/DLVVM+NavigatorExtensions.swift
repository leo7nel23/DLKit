//
//  DLVVM+NavigatorExtensions.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/7/18.
//

import Combine

public typealias Navigator = DLViewModel<NavigationFlow>

public extension Navigator {
    /// Binds a root view model to the navigation system
    /// 
    /// This method creates a root view model and establishes the necessary navigation
    /// bindings for routing and event handling.
    /// 
    /// - Parameters:
    ///   - state: The root business state
    ///   - reducer: The reducer for the root state
    /// - Returns: A bound root view model
    @MainActor
    func bindRootView<BizState: NavigatableState>(
        state: BizState,
        reducer: BizState.R
    ) -> DLViewModel<BizState> {
        let viewModel = _scope(
            state: state,
            event: nil, // as coordinator root view, you should only connect with navigator
            reducer: reducer,
            cacheKey: "Root"
        )
        bindRouter(viewModel: viewModel)

        return viewModel
    }

    func handleViewPopper(_ identifiers: [String]) {
        identifiers.forEach { [weak self] in
            self?.navigatableKeyPaths[$0]?()
            self?.navigatableKeyPaths[$0] = nil
        }
    }

    // 產生快取 key
    private func cacheKey<PastState, NextState>(
        keyPath: WritableKeyPath<PastState, NextState>,
        reducerType: Any.Type
    ) -> String {
        let keyPathString = String(describing: keyPath)
        let reducerString = String(describing: reducerType)
        return "\(keyPathString)_\(reducerString)"
    }

    private func navigatorScope<NextState: NavigatableState, PastState: BusinessState>(
        state keyPath: WritableKeyPath<PastState, NextState?>,
        to pastViewModel: DLViewModel<PastState>,
        event toPastAction: @escaping (NextState.R.Event) -> PastState.R.Action?,
        reducer nextReducer: NextState.R
    ) -> DLViewModel<NextState>? where NextState.R.State == NextState {
        guard let nextState = pastViewModel.state[keyPath: keyPath] else { return nil }
        let key = cacheKey(keyPath: keyPath, reducerType: type(of: nextReducer))

        if let cachedViewModel = childViewModels[key] as? DLViewModel<NextState> {
            return cachedViewModel
        }
        // scope next to past

        // 建立 presenting & presented 的 event 鏈結
        let nextViewModel = pastViewModel._scope(
            state: nextState,
            event: toPastAction,
            reducer: nextReducer,
            cacheKey: key
        ) // next will direct to past action now
        // 建立 presented & navigator 的 route 關係
        bindRouter(viewModel: nextViewModel)
        navigatableKeyPaths[nextViewModel.id] = { [pastViewModel] in
            pastViewModel.state[keyPath: keyPath] = nil
            pastViewModel.childViewModels[key] = nil
        }
        return nextViewModel
    }

    /// Binds a view model to the navigation router
    /// 
    /// This method sets up the necessary publishers and subscriptions for handling
    /// navigation events, route changes, and dismiss actions.
    /// 
    /// - Parameter viewModel: The view model to bind to the router
    private func bindRouter<BizState: NavigatableState>(
        viewModel: DLViewModel<BizState>
    ) {
        guard !(viewModel is Navigator) else { return }
        let fromAddress = "(\(Unmanaged<AnyObject>.passUnretained(viewModel.state).toOpaque()))"
        let from = String(describing: BizState.self.R) + fromAddress
        let toAddress = "(\(Unmanaged<AnyObject>.passUnretained(self.state).toOpaque()))"
        let to = String(describing: type(of: self.state).R) + toAddress

        viewModel.navigatorEventPublisher
            .print("⤴️ [Nav Event]: \(from) -> \(to)")
            .sink { [weak self] in
                self?.send(.subEvent($0))
            }
            .store(in: &subscription)


        viewModel.routePublisher
            .print("⤴️ [Router]: \(from) -> \(to)")
            .sink { [weak self, weak viewModel] futureStateInfo in
                guard let viewModel else { return }
                self?.handlePresent(from: viewModel, erased: futureStateInfo)
            }
            .store(in: &subscription)

        viewModel.routeDismissPublisher
            .print("⤵️ [Dismiss]: \(from) -> \(to)")
            .sink { [weak self] type in
                switch type {
                case .dismiss:
                    self?.send(.dismiss)

                case .dismissFullCover:
                    self?.send(.dismissFullScreenOver)

                case .dismissSheet:
                    self?.send(.dismissSheet)

                case .pop:
                    self?.send(.pop)

                case .popToRoot:
                    self?.send(.popToRoot)
                }
            }
            .store(in: &subscription)
    }

    /// Handles navigation presentation logic
    /// 
    /// This method processes navigation requests by matching them against registered
    /// state types and executing the appropriate presentation logic.
    /// 
    /// - Parameters:
    ///   - pastViewModel: The source view model initiating navigation
    ///   - erased: Type-erased navigation information
    private func handlePresent<PastState: NavigatableState>(
        from pastViewModel: DLViewModel<PastState>,
        erased: TypeErasedNextStateKeyPath<PastState>
    ) {
        for stateType in state.stateTypeList {
            let matcher = makeMatcher(from: pastViewModel, nil, stateType)
            if matcher.match(erased) != nil {
                return
            }
        }
        print("❌❌❌ [Error] Fail to map stateType, keyPath: \(erased._keyPath)")
    }

    private func makeMatcher<PastState: NavigatableState, Next: NavigatableState>(
        from pastViewModel: DLViewModel<PastState>,
        _ navigationViewModel: DLViewModel<NavigationFlow>? = nil,
        _: Next.Type
    ) -> NextStateMatcher<PastState> {
        .init(
            type: Next.self,
            match: { [weak self] erased in
                guard let self else { return }
                var skipRoute = false
                let result: ((any DLViewModelProtocol)?, RouteStyle)? = {
                    if let keyInfo = erased.typed(as: Next.self) {
                        guard let nextViewModel = navigatorScope(
                            state: keyInfo.keyPath,
                            to: pastViewModel,
                            event: keyInfo.eventMapper,
                            reducer: keyInfo.reducer
                        ) else { return nil }

                        // if it's navigator, look type from next
                        if let navigator = nextViewModel as? Navigator {
                            for stateType in navigator.stateTypeList {
                                let matcher = makeMatcher(from: pastViewModel, navigator, stateType)
                                if matcher.match(erased) != nil {
                                    break
                                }
                            }
                        }
                        return (
                            nextViewModel,
                            keyInfo.routeStyle
                        )
                    } else if let keyInfo = erased.navigationTyped(as: Next.self),
                              let navigationViewModel
                    {
                        let rootViewModel = navigationViewModel.bindRootView(
                            state: keyInfo.rootState,
                            reducer: keyInfo.rootReducer
                        )
                        navigationViewModel.state.setUp(rootViewModel: rootViewModel)

                        // swap cleaner to check for root popped
                        if keyInfo.routeStyle == .push {
                            navigatableKeyPaths[rootViewModel.id] = navigatableKeyPaths[navigationViewModel.id]
                            navigatableKeyPaths[navigationViewModel.id] = nil
                        }

                        skipRoute = true

                        return (rootViewModel, keyInfo.routeStyle)
                    } else {
                        return nil
                    }
                }()

                guard !skipRoute,
                      let nextViewModel = result?.0,
                      let routeStyle = result?.1
                else { return result?.0 }

                switch routeStyle {
                case .push:
                    send(.push(nextViewModel))

                case .fullScreenCover:
                    send(.presentFullScreenCover(nextViewModel))

                case .sheet:
                    send(.presentSheet(nextViewModel))
                }
                return nextViewModel
            }
        )
    }
}
