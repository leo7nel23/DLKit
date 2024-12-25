//
//  CoordinatorView.swift
//  DLKit
//
//  Created by 賴柏宏 on 2024/12/7.
//

import Foundation


public struct CoordinatorView<ViewModel: DLCoordinatorViewModel>: DLView {
  @Environment(\.dismiss) var dismiss

  @State public var observation: ViewModel.ViewObservation

  public let viewModel: ViewModel

  public init(viewModel: ViewModel) {
    self.viewModel = viewModel
    observation = viewModel.observation
  }

  public var body: some View {
    NavigationStack(
      path: $observation.path
    ) {
      viewModel.buildView(for: observation.root)
        .navigationDestination(for: ViewModel.T.self) {
          viewModel.buildView(for: $0)
        }
    }
    .sheet(item: $observation.sheet) {
      viewModel.buildView(for: $0)
    }
    .fullScreenCover(item: $observation.fullScreenCover) {
      viewModel.buildView(for: $0)
    }
    .onReceive(observation.onDismissSubject) { _ in
      dismiss()
    }
  }
}
