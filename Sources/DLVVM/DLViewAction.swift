//
//  File.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/2/4.
//

import Foundation

public protocol DLViewAction {
    associatedtype ViewAction

    func reduce(_ viewAction: ViewAction)
}
