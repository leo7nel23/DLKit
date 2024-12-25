//
//  
//  TagsFieldView.swift
//  
//
//  Created by 賴柏宏 on 2024/7/26.
//
//

import DLVVM
import FlowLayout

public struct TagsFieldView: DLView {

  public typealias ViewModel = TagsFieldViewModel

  @State public private(set) var observation: ViewModel.ViewObservation

  public let viewModel: ViewModel

  public init(viewModel: ViewModel) {
    self.viewModel = viewModel
    observation = viewModel.observation
  }

  public var body: some View {
    HFlow(alignment: .leading, verticalSpacing: 2, horizontalSpacing: 4) {
      ForEach(observation.tagViewModels) {
        TagViewView(viewModel: $0)
      }
    }
  }
}

#Preview {
  TagsFieldView(viewModel: .init(placeholder: "Symbol", defaultTags: ["QQQ", "ABC", "DD"]))
    .background(.gray)

}
