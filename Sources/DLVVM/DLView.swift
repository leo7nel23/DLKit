// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI

public typealias DLView = DevinLaiView

public protocol DevinLaiView: View {
  associatedtype ViewModel: DLPropertiesViewModel

  var viewModel: ViewModel { get }

  var observation: ViewModel.ViewObservation { get }

  init(viewModel: ViewModel)
}
