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

        @State public var viewModel: NavigationViewModel

        public init(viewModel: ViewModel) {
            self.viewModel = viewModel
        }

        public var body: some View {
            NavigationStack(
                path: $viewModel.manager.path
            ) {
                viewModel.buildView(for: viewModel.manager.root)
                    .navigationDestination(for: NavigatorInfo.self) {
                        viewModel.buildView(for: $0)
                    }
            }
            .sheet(item: $viewModel.manager.sheet) {
                viewModel.buildView(for: $0)
            }
            .fullScreenCover(item: $viewModel.manager.fullScreenCover) {
                viewModel.buildView(for: $0)
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
                presenting: viewModel.manager.alert) {
                    AnyView($0.viewBuilder())
                } message: {
                    Text($0.message)
                }
        }
    }
}
