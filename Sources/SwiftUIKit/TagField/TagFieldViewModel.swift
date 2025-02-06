//
//  
//  TagFieldViewModel.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/2/6.
//
//

import DLVVM

// MARK: - TagFieldViewModel

@Observable
public final class TagFieldViewModel: DLReducibleViewModel {
    public typealias Reducer = TagFieldFeature

    public var state: State

    public var coordinator: DLCoordinatorViewModel?

    public var subscriptions = Set<AnyCancellable>()

    public init(initialState: State) {
        state = initialState
        setUpSubscriptions()
    }

    private func setUpSubscriptions() {
        state.actionPublisher
            .sink { [weak self] action in
                guard let self = self else { return }
                switch action {
                    case .cleanNewTag:
                        self.newTag = ""

                    case let .newTagsUpdated(tags):
                        self.fireEvent(.tagUpdated(tags))

                    case .disableFocus:
                        self.disableFocusSubject.send(true)

                    case .enableFocus:
                        self.disableFocusSubject.send(false)

                }
            }
            .store(in: &subscriptions)

        state.$tags
            .sink { [weak self] in
                self?.tags = $0
            }
            .store(in: &subscriptions)
    }

    var prefix: String { state.prefix }
    var placeholder: String { state.placeholder }
    private(set) var disableFocusSubject = PassthroughSubject<Bool, Never>()

    private(set) var color: Color = Color(.sRGB, red: 50/255, green: 200/255, blue: 165/255)
    private(set) var tags: [String] = []

    var newTag: String = ""
}

extension TagFieldViewModel: DLEventPublisher {
    public enum Event {
        case tagUpdated([String])
    }
}

extension TagFieldViewModel: DLManipulation {
    public enum Manipulation {
        case updateTags([String])
    }

    public func manipulate(_ manipulation: Manipulation) {
        Reducer.reduce(state: state, with: manipulation)
    }
}

extension TagFieldViewModel: DLViewAction {
    public enum ViewAction {
        case removeTapped(String)
        case newTagUpdated(String)
        case newTagSubmitted(String)
    }

    public func reduce(_ viewAction: ViewAction) {
        Reducer.reduce(state: state, with: viewAction)
    }
}
