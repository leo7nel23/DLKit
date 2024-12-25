//
//  SearchBar.swift
//  DLKit
//
//  Created by 賴柏宏 on 2024/12/10.
//

import SwiftUI

public struct SearchBar: View {
  @Binding public private(set) var searchTerm: String
  public private(set) var placeholderText: String
  public private(set) var action: () -> Void

  public var body: some View {
    HStack {
      TextField(placeholderText, text: $searchTerm)
        .padding()

    }
  }
}
