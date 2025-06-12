//
//  VoidReducer.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/6/11.
//


public final class VoidReducer<ViewModel: DLViewModel>: BusinessReducer {
    public init() {}

    public typealias Action = Void

    public static func reduce(state: inout ViewModel.State, action: Void) {

    }
}
