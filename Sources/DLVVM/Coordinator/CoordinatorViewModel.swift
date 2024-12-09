//
//  
//  CoordinatorViewModel.swift
//  DLKit
//
//  Created by 賴柏宏 on 2024/12/9.
//
//

public protocol DestinationCase: Hashable & Identifiable {}

// MARK: - DefaultCoordinatorViewModel
final public class DefaultCoordinatorViewModel<T: DestinationCase>: DLPropertiesViewModel {

  public struct Configuration {
    let rootDestination: T
    let autoHideNavigationBar: Bool

    public init(rootDestination: T, autoHideNavigationBar: Bool) {
      self.rootDestination = rootDestination
      self.autoHideNavigationBar = autoHideNavigationBar
    }
  }

  public class Properties: DLProperties {
    public typealias ViewModel = DefaultCoordinatorViewModel

    let config: Configuration

    init(config: Configuration) {
      self.config = config
    }
  }

  lazy public internal(set) var observation: ViewObservation = makeViewObservation()

  public internal(set) var properties: Properties

  public var subscriptions = Set<AnyCancellable>()


  let viewBuilder: (T) -> any View

  public init(
    viewBuilder: @escaping (T) -> any View,
    config: Configuration
  ) {
    self.viewBuilder = viewBuilder
    self.properties = Properties(config: config)
  }
}

// work function
extension DefaultCoordinatorViewModel {
  public func push(_ destination: T) {
    observation.path.append(destination)
  }

  public func presentSheet(_ destination: T) {
    observation.sheet = destination
  }

  public func presentFullScreenCover(_ destination: T) {
    observation.fullScreenCover = destination
  }

  public func pop() {
    guard !observation.path.isEmpty else { return }
    observation.path.removeLast()
  }

  public func popToRoot() {
    observation.path.removeLast(observation.path.count)
  }

  public func dismissSheet() {
    observation.sheet = nil
  }

  public func dismissFullScreenOver() {
    observation.fullScreenCover = nil
  }

  public func dismissLastView() {
    if observation.sheet != nil {
      dismissSheet()
    } else if observation.fullScreenCover != nil {
      dismissFullScreenOver()
    } else {
      pop()
    }
  }

  func buildView(for destination: T) -> AnyView {
    var view = viewBuilder(destination)
    if let dlView = view as? (any DLView),
       let viewModel = dlView.viewModel as? (any DLCoordinatable) {
      viewModel.set(coordinator: self)
    }
    if properties.config.autoHideNavigationBar {
      if #available(iOS 18.0, *) {
        view = view.toolbarVisibility(.hidden, for: .navigationBar)
      } else {
        view = view.navigationBarHidden(true)
      }
    }
    return AnyView(view)
  }
}

public extension DefaultCoordinatorViewModel {
  @Observable
  class ViewObservation {
    let root: T
    var path: [T] = []
    var sheet: T?
    var fullScreenCover: T?

    init(root: T) {
      self.root = root
    }
  }

  private func makeViewObservation() -> ViewObservation {
    ViewObservation(
      root: properties.config.rootDestination
    )
  }
}
