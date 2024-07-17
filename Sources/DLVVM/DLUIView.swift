//
//  DLUIView.swift
//
//
//  Created by 賴柏宏 on 2024/7/18.
//

import SwiftUI

public typealias DLUIView = DevinLaiUIView

public protocol DevinLaiUIView: UIView {
  associatedtype ViewModel: DevinLaiViewModel

  var viewModel: ViewModel { get }

  var observation: ViewModel.ViewObservation { get }

  init(viewModel: ViewModel)
}


// MARK: - DefaultDevinLaiUIView

public typealias DefaultDLUIView = DefaultDevinLaiUIView

open class DefaultDevinLaiUIView<ViewModel: DLViewModel>: UIView, DLUIView {
  public var observation: ViewModel.ViewObservation

  public let viewModel: ViewModel

  private var subscriptions = Set<AnyCancellable>()

  public required init(viewModel: ViewModel) {
    self.viewModel = viewModel
    observation = viewModel.observation
    super.init(frame: .zero)
    setUp()
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func setUp() {
    setUpUserInterfaces()
    setUpSubscriptions(viewModel: viewModel, subscriptions: &subscriptions)
  }

  open func setUpUserInterfaces() {}

  open func setUpSubscriptions(viewModel: ViewModel, subscriptions: inout Set<AnyCancellable>) {}
}
