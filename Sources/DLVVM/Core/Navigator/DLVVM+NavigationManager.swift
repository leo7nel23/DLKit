//
//  NavigationManager.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/2/7.
//

import Foundation
import Combine
import SwiftUI

public typealias CoordinatorViewBuilder = (any DLViewModelProtocol) -> (any View)?

public extension DLVVM {
    @Observable
    class Navigator {
        @ObservationIgnored
        private var isUserPop = false

        @ObservationIgnored
        private var paths: [[NavigatorInfo]] = [[]] {
            didSet {
                if !isUserPop {
                    path = paths.flatMap { $0 }
                } else {
                    isUserPop = false
                }
            }
        }

        var path: [NavigatorInfo] = [] {
            didSet {
                // Update NavigationFlow's pathCount
                navigationFlow?.pathCount = path.count

                if path.count < oldValue.count { // user pop
                    syncBackToPaths()
                }
            }
        }
        var root: NavigatorInfo
        var sheet: NavigatorInfo?
        var fullScreenCover: NavigatorInfo?
        var alert: AlertViewModel?

        @ObservationIgnored
        var onDismissSubject = PassthroughSubject<Void, Never>()

        @ObservationIgnored
        weak var navigationFlow: NavigationFlow?

        private var viewBuilders: [CoordinatorViewBuilder] = []

        private var coordinators: [String] = []

        init(
            rootInfo: NavigatorInfo,
            id: String,
            viewBuilder: @escaping CoordinatorViewBuilder,
            navigationFlow: NavigationFlow? = nil
        ) {
            self.root = rootInfo
            self.coordinators = [id]
            self.viewBuilders = [viewBuilder]
            self.navigationFlow = navigationFlow
        }

        func syncBackToPaths() {
            var targetCount = path.count
            let newPaths = paths.enumerated().compactMap { (index, subPath) -> [NavigatorInfo]? in
                if targetCount == 0 {
                    return index == 0 ? [] : nil
                } else if subPath.count > targetCount {
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
            with root: NavigatorInfo,
            viewBuilder: @escaping CoordinatorViewBuilder
        ) {
            guard !coordinators.contains(id) else { return }
            paths.append([root])
            viewBuilders.append(viewBuilder)
            coordinators.append(id)
        }

        func push(_ viewModel: NavigatorInfo) {
            let lastIndex = paths.count - 1
            guard lastIndex >= 0 else { return }
            paths[lastIndex].append(viewModel)
        }

        func alert(_ viewModel: AlertViewModel) {
            alert = viewModel
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

        func buildView(for hashableViewModel: NavigatorInfo) -> AnyView {
            for builder in viewBuilders {
                if let view = builder(hashableViewModel.viewModel) {
                    return AnyView(view)
                }
            }

            return AnyView(EmptyView())
        }
    }
}
