//
//
//  NavigationViewModel.swift
//  DLKit
//
//  Created by 賴柏宏 on 2024/12/9.
//
//

import Combine

public typealias NavigationState = DLVVM.NavigationState
public typealias NavigationReducer = DLVVM.NavigationReducer
public typealias Navigator = DLViewModel<NavigationState>

public extension Navigator {
    @MainActor
    func bindRootView<BizStata: NavigatableState>(
        state: BizStata,
        reducer: BizStata.R
    ) -> DLViewModel<BizStata> {
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
    }

    private func makeMatcher<PastState: NavigatableState, Next: NavigatableState>(
        from pastViewModel: DLViewModel<PastState>,
        _ navigationViewModel: DLViewModel<NavigationState>? = nil,
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

// MARK: - DLVVM.NavigationViewModel

public extension DLVVM {
    final class NavigationState: NavigatableState, @unchecked Sendable, Identifiable {
        public typealias R = NavigationReducer
        public typealias NavigatorEvent = Void

        public let id: String = UUID().uuidString

        let viewBuilder: CoordinatorViewBuilder

        private(set) var rootInfo: NavigatorInfo!
        var manager: NavigationManager!

        let stateTypeList: [any NavigatableState.Type]

        public let eventHandler: ((Any) -> Any?)?

        public init(
            stateTypeList: [any NavigatableState.Type],
            viewBuilder: @escaping CoordinatorViewBuilder,
            eventHandler: ((Any) -> Any?)? = nil
        ) {
            var list = stateTypeList
            list.append(NavigationState.self)
            self.stateTypeList = list
            self.viewBuilder = viewBuilder
            self.eventHandler = eventHandler
        }

        func setUp(rootViewModel: any DLViewModelProtocol) {
            rootInfo = NavigatorInfo(viewModel: rootViewModel)
            if manager == nil {
                manager = NavigationManager(
                    rootInfo: rootInfo,
                    id: id,
                    viewBuilder: viewBuilder
                )
            }
        }

        @MainActor
        func buildView(for navigatorInfo: NavigatorInfo) -> AnyView {
            let view: any View = {
                if let navigator = navigatorInfo.viewModel as? Navigator {
                    DLNavigationView(viewModel: navigator)
                } else {
                    manager.buildView(for: navigatorInfo)
                }
            }()
            return AnyView(view)
        }
    }

    final class NavigationReducer: Reducer {
        public typealias State = NavigationState
        public typealias Event = Any

        public enum Action {
            case push(any DLViewModelProtocol)
            case presentSheet(any DLViewModelProtocol)
            case presentFullScreenCover(any DLViewModelProtocol)
            case pop
            case popToRoot
            case dismissSheet
            case dismissFullScreenOver
            case dismiss
            case alert(title: String, message: String)
            case subEvent(Any)
        }

        public init() {}

        public func reduce(
            into state: NavigationState,
            action: Action
        ) -> DLVVM.Procedure<Action, State> {
            switch action {
            case let .push(viewModel):
                if let newState = viewModel.state as? NavigationState {
                    state.manager.createNewPath(
                        for: newState.id,
                        with: newState.rootInfo,
                        viewBuilder: newState.viewBuilder
                    )
                    newState.manager = state.manager
                } else {
                    let info = NavigatorInfo(viewModel: viewModel)
                    state.manager.push(info)
                }

            case let .presentSheet(businessState):
                let info = NavigatorInfo(viewModel: businessState)
                state.manager.sheet = info

            case let .presentFullScreenCover(businessState):
                let info = NavigatorInfo(viewModel: businessState)
                state.manager.fullScreenCover = info

            case .pop:
                state.manager.pop()

            case .popToRoot:
                state.manager.popToRoot()

            case .dismissSheet:
                state.manager.sheet = nil

            case .dismissFullScreenOver:
                state.manager.fullScreenCover = nil

            case .dismiss:
                state.manager.dismiss()

            case let .subEvent(event):
                if let result = state.eventHandler?(event) {
                    fireEvent(result, with: state)
                }

            case .alert:
                break
            }

            return .none
        }
    }
}
