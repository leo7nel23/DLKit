//
//  DLProperties.swift
//
//
//  Created by 賴柏宏 on 2024/7/30.
//

import Foundation
import Combine

public typealias DLProperties = DevinLaiProperties

public protocol DLPropertiesViewModel: DLViewModel {
  associatedtype Properties: DevinLaiProperties where Properties.ViewModel == Self

  associatedtype ViewObservation

  var properties: Properties { get }
  var observation: ViewObservation { get }
  var subscriptions: Set<AnyCancellable> { get set }
}

public protocol DevinLaiProperties {
  associatedtype ViewModel: DLPropertiesViewModel
}


fileprivate var eventSubjectAssociatedKey: Void?

extension DLProperties where ViewModel: DLEventPublisher {

    var eventSubject: PassthroughSubject<ViewModel.Event, Never> {
        if let subject = objc_getAssociatedObject(self, &eventSubjectAssociatedKey) as? PassthroughSubject<ViewModel.Event, Never> {
            return subject
        } else {
            let subject = PassthroughSubject<ViewModel.Event, Never>()
            objc_setAssociatedObject(self, &eventSubjectAssociatedKey, subject, .OBJC_ASSOCIATION_RETAIN)
            return subject
        }
    }

    var eventPublisher: AnyPublisher<ViewModel.Event, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    internal func fireEvent(_ event: ViewModel.Event) {
        eventSubject.send(event)
    }

}
