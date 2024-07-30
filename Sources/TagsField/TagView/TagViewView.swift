//
//  
//  DLTagViewView.swift
//  
//
//  Created by 賴柏宏 on 2024/7/26.
//
//

import DLVVM

struct DLTagViewView: DLView {

  typealias ViewModel = DLTagViewViewModel

  @State var observation: ViewModel.ViewObservation

  @FocusState var isFocused

  let viewModel: ViewModel

  init(viewModel: ViewModel) {
    self.viewModel = viewModel
    observation = viewModel.observation
  }

  var body: some View {
    TextField("Tags", text: $observation.tag)
      .focused($isFocused)
      .padding(.horizontal, isFocused || observation.tag.isEmpty ? 0 : 10)
      .padding(.vertical, 10)
      .background(observation.isAbleToEdit ? .clear : Color.white)
      .disabled(!observation.isAbleToEdit)
      .clipShape(.capsule)
      .lineLimit(1)
      .fixedSize(horizontal: true, vertical: false)
      .onChange(of: observation.tag) { _, newValue in
        viewModel.handle(.updateTag(newValue))
      }
      .onKeyPress(.delete, action: {
        viewModel.handle(.deleteTapped)
        return .ignored
      })
      .onChange(of: observation.isFocused, { _, newValue in
        isFocused = newValue
      })
      .onAppear {
        isFocused = true
      }
  }
}

#Preview {
  DLTagViewView(viewModel: .init())
}