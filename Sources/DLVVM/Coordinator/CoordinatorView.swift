//
//  CoordinatorView.swift
//  DLKit
//
//  Created by 賴柏宏 on 2024/12/7.
//

import Foundation


public struct CoordinatorView<T: DestinationCase>: DLView {
  @State public var observation: ViewModel.ViewObservation

  public let viewModel: DefaultCoordinatorViewModel<T>

  public init(viewModel: ViewModel) {
    self.viewModel = viewModel
    observation = viewModel.observation
  }

  public var body: some View {
    NavigationStack(
      path: $observation.path
    ) {
      viewModel.buildView(for: observation.root)
        .navigationDestination(for: T.self) {
          viewModel.buildView(for: $0)
        }
    }
    .sheet(item: $observation.sheet) {
      viewModel.buildView(for: $0)
    }
    .fullScreenCover(item: $observation.fullScreenCover) {
      viewModel.buildView(for: $0)
    }
  }
}
