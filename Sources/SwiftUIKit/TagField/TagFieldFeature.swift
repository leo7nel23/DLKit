//
//  
//  TagFieldFeature.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/2/6.
//
//

import Combine
import DLVVM
import Foundation

// MARK: - TagFieldViewModel.Properties

public extension TagFieldViewModel {
    final class State: DLState {
        public typealias ViewModel = TagFieldViewModel

        fileprivate let actionSubject = PassthroughSubject<Action, Never>()
        var actionPublisher: AnyPublisher<Action, Never> { actionSubject.eraseToAnyPublisher() }

        enum Action {
            case cleanNewTag
            case newTagsUpdated([String])
            case disableFocus
            case enableFocus
        }

        @Published fileprivate(set) var tags: [String]
        let prefix: String
        let placeholder: String

        public init(tags: [String] = [], prefix: String = "", placeholder: String = "") {
            self.tags = tags
            self.prefix = prefix
            self.placeholder = placeholder
        }
    }
}

// MARK: - TagFieldFeature

public enum TagFieldFeature: DLReducer {
    public typealias ViewModel = TagFieldViewModel
    public typealias State = ViewModel.State

    public enum Action {
    }

    public static func reduce(state: State, action: Action) {
    }

    static func reduce(state: State, with action: ViewModel.ViewAction) {
        switch action {
            case let .removeTapped(tag):
                state.tags.removeAll { $0 == tag }
                state.actionSubject.send(.newTagsUpdated(state.tags))

            case let .newTagUpdated(newTag):
                appendNewTag(state: state, with: newTag, isEnded: false)

            case let .newTagSubmitted(newTag):
                appendNewTag(state: state, with: newTag, isEnded: true)

        }
    }

    static func appendNewTag(state: State, with tag: String, isEnded: Bool) {
        func isBlank(tag: String) -> Bool {
            let tmp = tag.trimmingCharacters(in: .whitespaces)
            return tmp == ""
        }

        guard !isBlank(tag: tag) else {
            state.actionSubject.send(.cleanNewTag)
            return
        }
        func commit(newTag: String) {
            defer {
                state.actionSubject.send(.cleanNewTag)
            }
            guard !state.tags.contains(newTag) else { return }
            let newTag = newTag.uppercased()
            state.tags.append(newTag)
            state.actionSubject.send(.newTagsUpdated(state.tags))
            state.actionSubject.send(.enableFocus)
        }
        var newTag = tag
        if newTag.last == " " {
            newTag.removeLast()
            commit(newTag: newTag)
        } else if isEnded {
            commit(newTag: newTag)
        }
    }

    static func reduce(state: State, with manipulation: ViewModel.Manipulation) {
        switch manipulation {
            case let .updateTags(tags):
                guard tags != state.tags else { return }
                state.tags = tags
                state.actionSubject.send(.cleanNewTag)
                state.actionSubject.send(.disableFocus)
        }
    }
}
