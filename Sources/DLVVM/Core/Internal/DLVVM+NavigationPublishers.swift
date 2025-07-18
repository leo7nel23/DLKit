//
//  DLVVM+NavigationPublishers.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/7/18.
//

import Foundation
import Combine

nonisolated(unsafe) private var routeInfoSubjectAssociatedKey: Void?

extension DLVVM.NavigatableState {
    typealias RouteInfo = TypeErasedNextStateKeyPath<Self>
    var routeSubject: PassthroughSubject<RouteInfo, Never> {
        if let subject = objc_getAssociatedObject(
            self,
            &routeInfoSubjectAssociatedKey
        ) as? PassthroughSubject<RouteInfo, Never> {
            return subject
        } else {
            let subject = PassthroughSubject<RouteInfo, Never>()
            objc_setAssociatedObject(
                self,
                &routeInfoSubjectAssociatedKey,
                subject,
                .OBJC_ASSOCIATION_RETAIN
            )
            return subject
        }
    }

    var routePublisher: AnyPublisher<RouteInfo, Never> {
        routeSubject.eraseToAnyPublisher()
    }

    internal func route(destination: RouteInfo) {
        routeSubject.send(destination)
    }
}

nonisolated(unsafe) private var routeDismissSubjectAssociatedKey: Void?

extension DLVVM.NavigatableState {
    private var routeDismissSubject: PassthroughSubject<DismissType, Never> {
        if let subject = objc_getAssociatedObject(
            self,
            &routeDismissSubjectAssociatedKey
        ) as? PassthroughSubject<DismissType, Never> {
            return subject
        } else {
            let subject = PassthroughSubject<DismissType, Never>()
            objc_setAssociatedObject(
                self,
                &routeDismissSubjectAssociatedKey,
                subject,
                .OBJC_ASSOCIATION_RETAIN
            )
            return subject
        }
    }

    var routeDismissPublisher: AnyPublisher<DismissType, Never> {
        routeDismissSubject.eraseToAnyPublisher()
    }

    internal func dismiss(_ type: DismissType) {
        routeDismissSubject.send(type)
    }
}

nonisolated(unsafe) private var navigatorEventSubjectAssociatedKey: Void?

extension DLVVM.NavigatableState {
    private var navigatorEventSubject: PassthroughSubject<NavigatorEvent, Never> {
        if let subject = objc_getAssociatedObject(
            self,
            &navigatorEventSubjectAssociatedKey
        ) as? PassthroughSubject<NavigatorEvent, Never> {
            return subject
        } else {
            let subject = PassthroughSubject<NavigatorEvent, Never>()
            objc_setAssociatedObject(
                self,
                &navigatorEventSubjectAssociatedKey,
                subject,
                .OBJC_ASSOCIATION_RETAIN
            )
            return subject
        }
    }

    var navigatorEventPublisher: AnyPublisher<NavigatorEvent, Never> {
        navigatorEventSubject.eraseToAnyPublisher()
    }

    func fireNavigatorEvent(_ event: NavigatorEvent) {
        navigatorEventSubject.send(event)
    }
}