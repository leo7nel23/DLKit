//
//  
//  TagFieldView.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/2/6.
//
//

import DLVVM
import FlowLayout

public struct TagFieldView: DLView {
    @State public var viewModel: TagFieldViewModel
    @FocusState private var isFocused: Bool

    public init(viewModel: TagFieldViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        HFlow {
            ForEach(viewModel.tags, id: \.self) { tag in
                makeTagView(tag)
            }

            makeTextField()
        }
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(viewModel.color, lineWidth: 0.75)
        )
        .background(.gray.opacity(0.07))
        .onTapGesture {
            isFocused = !isFocused
        }
        .onReceive(viewModel.disableFocusSubject) { isFocused = !$0 }
    }

    @ViewBuilder
    private func makeTagView(_ tag: String) -> some View {
        HStack {
            Text("\(viewModel.prefix + tag)")
                .fixedSize()
                .foregroundStyle(viewModel.color.opacity(0.8))
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .padding(.leading, 10)
                .padding(.vertical, 5)

            Button {
                send(.removeTapped(tag))
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(viewModel.color.opacity(0.8))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .padding(.trailing, 10)
            }
        }
        .background(viewModel.color.opacity(0.1))
        .clipShape(.capsule)
    }

    @ViewBuilder
    private func makeTextField() -> some View {
        TextField(viewModel.placeholder, text: $viewModel.newTag)
            .focused($isFocused)
            .onChange(of: viewModel.newTag, { _, new in
                if !new.isEmpty {
                    send(.newTagUpdated(viewModel.newTag))
                }
            })
            .onSubmit { send(.newTagSubmitted(viewModel.newTag)) }
            .fixedSize()
            .disableAutocorrection(true)
            .autocapitalization(.none)
            .accentColor(viewModel.color)
            .padding(.vertical, 5)
            .padding(.trailing)
    }
}

#Preview {
    TagFieldView(viewModel: .init(initialState: .init(tags: ["SS"], placeholder: "Add")))
}
