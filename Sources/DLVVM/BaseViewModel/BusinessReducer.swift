//
//  DLReducer.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/2/4.
//

import Foundation

public typealias BusinessReducer = DLVVM.BusinessReducer

public extension DLVVM {
    protocol BusinessReducer {
        associatedtype ViewModel: DLViewModel
        associatedtype Action

        typealias State = ViewModel.State

        static func reduce(state: inout State, action: Action)
    }
}
