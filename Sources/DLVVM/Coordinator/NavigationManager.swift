//
//  File.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/2/7.
//

import Foundation

public typealias CoordinatorViewBuilder = (DLViewModel) -> (any View)?

public extension CoordinatorView {
    @MainActor
    @Observable
    class NavigationManager {
        @ObservationIgnored
        private var isUserPop = false

        @ObservationIgnored
        private var paths: [[CoordinatorableViewModel]] = [[]] {
            didSet {
                if !isUserPop {
                    path = paths.flatMap { $0 }
                } else {
                    isUserPop = false
                }
            }
        }
        var path: [CoordinatorableViewModel] = [] {
            didSet {
                if path.count < oldValue.count { // user pop
                    syncBackToPaths()
                }
            }
        }
        var root: CoordinatorableViewModel
        var sheet: CoordinatorableViewModel?
        var fullScreenCover: CoordinatorableViewModel?

        @ObservationIgnored
        var onDismissSubject = PassthroughSubject<Void, Never>()

        private var viewBuilders: [CoordinatorViewBuilder] = []

        private var coordinators: [String] = []

        init(
            rootViewModel: CoordinatorableViewModel,
            id: String,
            viewBuilder: @escaping CoordinatorViewBuilder
        ) {
            self.root = rootViewModel
            self.coordinators = [id]
            self.viewBuilders = [viewBuilder]
        }

        func syncBackToPaths() {
            var targetCount = path.count
            let newPaths = paths.enumerated().compactMap { (index, subPath) -> [CoordinatorableViewModel]? in
                if targetCount == 0 {
                    return index == 0 ? [] : nil
                } else if subPath.count > targetCount {
                    targetCount = 0
                    return Array(subPath[0..<targetCount])
                } else {
                    targetCount -= subPath.count
                    return subPath
                }
            }

            isUserPop = true
            paths = newPaths
            coordinators = Array(coordinators[0..<paths.count])
            viewBuilders = Array(viewBuilders[0..<paths.count])
        }

        func createNewPath(
            for id: String,
            with root: CoordinatorableViewModel,
            viewBuilder: @escaping CoordinatorViewBuilder
        ) {
            guard !coordinators.contains(id) else { return }
            paths.append([root])
            viewBuilders.append(viewBuilder)
            coordinators.append(id)
        }

        func push(_ viewModel: CoordinatorableViewModel) {
            let lastIndex = paths.count - 1
            guard lastIndex >= 0 else { return }
            paths[lastIndex].append(viewModel)
        }

        func pop() {
            let lastIndex = paths.count - 1
            guard lastIndex >= 0,
                  !paths[lastIndex].isEmpty else { return }
            paths[lastIndex].removeLast()
        }

        func popToRoot() {
            let lastIndex = paths.count - 1
            guard lastIndex >= 0 else {
                return
            }

            if lastIndex == 0 {
                paths[lastIndex].removeAll()
            } else if let root = paths[lastIndex].first {
                paths[lastIndex] = [root]
            }
        }

        func dismiss() {
            let lastIndex = paths.count - 1
            guard lastIndex >= 0 else {
                return
            }

            if lastIndex == 0 {
                onDismissSubject.send()
            } else {
                paths.removeLast()
                coordinators = Array(coordinators[0..<paths.count])
                viewBuilders = Array(viewBuilders[0..<paths.count])
            }
        }

        func buildView(for hashableViewModel: CoordinatorableViewModel) -> AnyView {
            for builder in viewBuilders {
                if let view = builder(hashableViewModel.viewModel) {
                    return AnyView(view)
                }
            }

            return AnyView(EmptyView())
        }
    }
}
