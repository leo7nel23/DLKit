//
//
//  CoordinatorViewModel.swift
//  DLKit
//
//  Created by 賴柏宏 on 2024/12/9.
//
//

import Combine

public protocol DestinationCase: Hashable & Identifiable {}

public struct CoordinatorConfiguration<T> {
  let rootDestination: T
  let autoHideNavigationBar: Bool

  public init(rootDestination: T, autoHideNavigationBar: Bool) {
    self.rootDestination = rootDestination
    self.autoHideNavigationBar = autoHideNavigationBar
  }
}

public typealias DLCoordinatorViewModel = DevinLaiCoordinatorViewModel

public protocol DevinLaiCoordinatorViewModel: DLViewModel where ViewObservation: DefaultCoordinatorObservation<T> {
  associatedtype T: DestinationCase

  func push(_ destination: T)
  func presentSheet(_ destination: T)
  func presentFullScreenCover(_ destination: T)
  func pop()
  func popToRoot()
  func dismiss()
  func dismissSheet()
  func dismissFullScreenOver()
  func view(for destination: T) -> any View

  var observation: ViewObservation { get }
}

@Observable
open class DefaultCoordinatorObservation<Destination: DestinationCase> {
  var path: [Destination] = []
  var sheet: Destination?
  var fullScreenCover: Destination?
  var root: Destination
  var onDismissSubject = PassthroughSubject<Void, Never>()

  public init(root: Destination) {
    self.root = root
  }
}

public extension DevinLaiCoordinatorViewModel {
  func push(_ destination: T) {
    observation.path.append(destination)
  }

  func presentSheet(_ destination: T) {
    observation.sheet = destination
  }

  func presentFullScreenCover(_ destination: T) {
    observation.fullScreenCover = destination
  }

  func pop() {
    guard !observation.path.isEmpty else { return }
    observation.path.removeLast()
  }

  func popToRoot() {
    observation.path.removeLast(observation.path.count)
  }

  func dismiss() {
    observation.onDismissSubject.send()
  }

  func dismissSheet() {
    observation.sheet = nil
  }

  func dismissFullScreenOver() {
    observation.fullScreenCover = nil
  }

  func buildView(for destination: T) -> AnyView {
    let view = view(for: destination)
    if let view = view as? any DLView,
       let viewModel = view.viewModel as? (any DLCoordinatable) {
      viewModel.set(coordinator: self)
    }
    return AnyView(view)
  }
}
