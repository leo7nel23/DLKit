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

@Observable
public class DLCoordinatorViewModel: DLViewModel {
    var path: [DLCoordinatorableViewModel] = []
    var root: DLCoordinatorableViewModel
    var sheet: DLCoordinatorableViewModel?
    var fullScreenCover: DLCoordinatorableViewModel?

    @ObservationIgnored
    var onDismissSubject = PassthroughSubject<Void, Never>()

    @ObservationIgnored
    var result: Any?

    let viewBuilder: (DLViewModel) -> any View
    let callback: CoordinatorCallback<Any?>?

    public init(
        rootViewModel: DLViewModel,
        viewBuilder: @escaping (DLViewModel) -> any View,
        callback: CoordinatorCallback<Any?>? = nil
    ) {
        self.root = DLCoordinatorableViewModel(viewModel: rootViewModel)
        self.viewBuilder = viewBuilder
        self.callback = callback
    }

    public func push(_ viewModel: DLViewModel) {
        path.append(DLCoordinatorableViewModel(viewModel: viewModel))
    }

    public func presentSheet(_ viewModel: DLViewModel) {
        sheet = DLCoordinatorableViewModel(viewModel: viewModel)
    }

    public func presentFullScreenCover(_ viewModel: DLViewModel) {
        fullScreenCover = DLCoordinatorableViewModel(viewModel: viewModel)
    }

    public func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    public func popToRoot() {
        path.removeLast(path.count)
    }

    public func dismissSheet() {
        sheet = nil
    }

    public func dismissFullScreenOver() {
        fullScreenCover = nil
    }

    public func dismiss(runCallback: Bool = true) {
        if runCallback {
            callback?.run(result)
        }
        onDismissSubject.send()
    }

    public func update(result: Any?) {
        self.result = result
    }

    func buildView(for hashableViewModel: DLCoordinatorableViewModel) -> AnyView {
        func setCoordinator(viewModel: DLViewModel) {
            if let viewModel = viewModel as? (any DLReducibleViewModel) {
                viewModel.coordinator = self
            }
        }

        let view: any View = {
            if let coordinatorViewModel = hashableViewModel.viewModel as? DLCoordinatorViewModel {
                setCoordinator(viewModel: coordinatorViewModel.root.viewModel)
                return CoordinatorView(viewModel: coordinatorViewModel)
            } else {
                setCoordinator(viewModel: hashableViewModel.viewModel)
                return viewBuilder(hashableViewModel.viewModel)
            }
        }()
        return AnyView(view)
    }
}
