//
//  
//  DLTagsFieldView.swift
//  
//
//  Created by 賴柏宏 on 2024/7/26.
//
//

import DLVVM
import FlowLayout

public struct DLTagsFieldView: DLView {

  public typealias ViewModel = DLTagsFieldViewModel

  @State public private(set) var observation: ViewModel.ViewObservation

  public let viewModel: ViewModel

  public init(viewModel: ViewModel) {
    self.viewModel = viewModel
    observation = viewModel.observation
  }

  public var body: some View {
    HFlow {
      ForEach(observation.tagViewModels) {
        DLTagViewView(viewModel: $0)
      }
    }
  }
}

#Preview {
  DLTagsFieldView(viewModel: .init())
    .background(.gray)

}
