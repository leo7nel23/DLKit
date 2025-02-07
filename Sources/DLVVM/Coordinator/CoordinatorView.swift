//
//  CoordinatorView.swift
//  DLKit
//
//  Created by 賴柏宏 on 2024/12/7.
//

import Foundation
import SwiftUI

public struct CoordinatorView: DLView {
    @Environment(\.dismiss) var dismiss

    @State public var viewModel: DLCoordinatorViewModel

    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack(
            path: $viewModel.manager.path
        ) {
            viewModel.buildView(for: viewModel.manager.root)
                .navigationDestination(for: DLCoordinatorableViewModel.self) {
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
    }
}
