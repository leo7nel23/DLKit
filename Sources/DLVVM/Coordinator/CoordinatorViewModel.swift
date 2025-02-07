//
//
//  CoordinatorViewModel.swift
//  DLKit
//
//  Created by 賴柏宏 on 2024/12/9.
//
//

import Combine

class DLCoordinatorableViewModel: Hashable, Identifiable, CustomStringConvertible {
    var description: String { "\(modelType) at \(address)" }
    let id: String

    let viewModel: DLViewModel
    let modelType: String
    let address: String

    init(viewModel: DLViewModel) {
        self.viewModel = viewModel
        self.modelType = String(describing: type(of: viewModel).self)
        self.address = "\(Unmanaged<AnyObject>.passUnretained(viewModel).toOpaque())"

        if let viewModel = viewModel as? (any Identifiable) {
            self.id = "\(viewModel.id)"
        } else {
            self.id = "\(modelType) at \(address)"
        }
    }

    static func == (lhs: DLCoordinatorableViewModel, rhs: DLCoordinatorableViewModel) -> Bool {
        let lhsType = type(of: lhs.viewModel)
        let rhsType = type(of: rhs.viewModel)
        guard  lhsType == rhsType else { return false }

        return lhs.hashValue == rhs.hashValue
    }

    func hash(into hasher: inout Hasher) {
        if let hashable = viewModel as? (any Hashable) {
            hasher.combine(hashable)
        } else {
            hasher.combine(modelType)
            hasher.combine(address)
        }
    }
}

public class DLCoordinatorViewModel: DLViewModel {
    var manager: NavigationManager
    let id: String = UUID().uuidString
    var root: DLCoordinatorableViewModel
    var result: Any?

    let viewBuilder: CoordinatorViewBuilder
    let callback: CoordinatorCallback<Any?>?

    public init(
        rootViewModel: DLViewModel,
        viewBuilder: @escaping CoordinatorViewBuilder,
        callback: CoordinatorCallback<Any?>? = nil,
        autoHideNavigationBar: Bool = true
    ) {
        let root =  DLCoordinatorableViewModel(viewModel: rootViewModel)
        self.root = root
        self.viewBuilder = viewBuilder
        self.callback = callback
        self.manager = NavigationManager(rootViewModel: root, viewBuilder: viewBuilder)
    }

    public func push(_ viewModel: DLViewModel) {
        if let coordinatorViewModel = viewModel as? DLCoordinatorViewModel {
            setCoordinator(viewModel: coordinatorViewModel.root.viewModel)
            manager.createNewPath(
                for: coordinatorViewModel.id,
                with: coordinatorViewModel.root,
                viewBuilder: coordinatorViewModel.viewBuilder
            )
            coordinatorViewModel.manager = manager
        } else {
            manager.push(DLCoordinatorableViewModel(viewModel: viewModel))
        }
    }

    public func presentSheet(_ viewModel: DLViewModel) {
        manager.sheet = DLCoordinatorableViewModel(viewModel: viewModel)
    }

    public func presentFullScreenCover(_ viewModel: DLViewModel) {
        manager.fullScreenCover = DLCoordinatorableViewModel(viewModel: viewModel)
    }

    public func pop() {
        manager.pop()
    }

    public func popToRoot() {
        manager.popToRoot()
    }

    public func dismissSheet() {
        manager.sheet = nil
    }

    public func dismissFullScreenOver() {
        manager.fullScreenCover = nil
    }

    public func dismiss(runCallback: Bool = true) {
        if runCallback {
            callback?.run(result)
        }
        manager.dismiss()
    }

    public func update(result: Any?) {
        self.result = result
    }

    private func setCoordinator(viewModel: DLViewModel) {
        if let viewModel = viewModel as? (any DLReducibleViewModel) {
            viewModel.coordinator = self
        }
    }

    func buildView(for hashableViewModel: DLCoordinatorableViewModel) -> AnyView {
        let view: any View = {
            if let coordinatorViewModel = hashableViewModel.viewModel as? DLCoordinatorViewModel {
                setCoordinator(viewModel: coordinatorViewModel.manager.root.viewModel)
                return CoordinatorView(viewModel: coordinatorViewModel)
            } else {
                setCoordinator(viewModel: hashableViewModel.viewModel)
                return manager.buildView(for: hashableViewModel)
            }
        }()
        return AnyView(view)
    }
}
