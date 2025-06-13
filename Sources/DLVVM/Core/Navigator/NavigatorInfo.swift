//
//  NavigatorInfo.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/6/11.
//

import Foundation

struct NavigatorInfo: Hashable, Identifiable {
    var description: String { "\(modelType) at \(address)" }
    
    let id: String

    let state: any BusinessState
    let modelType: String
    let address: String

    init(state: any BusinessState) {
        if let id = (state as? (any Identifiable))?.id as? String {
            self.id = id
        } else {
            self.id = UUID().uuidString
        }
        self.state = state
        self.modelType = String(describing: type(of: state).self)
        self.address = "\(Unmanaged<AnyObject>.passUnretained(state).toOpaque())"
    }

    static func == (lhs: NavigatorInfo, rhs: NavigatorInfo) -> Bool {
        let lhsType = type(of: lhs.state)
        let rhsType = type(of: rhs.state)
        guard  lhsType == rhsType else { return false }

        return lhs.hashValue == rhs.hashValue
    }

    func hash(into hasher: inout Hasher) {
        if let hashable = state as? (any Hashable) {
            hasher.combine(hashable)
        } else {
            hasher.combine(modelType)
            hasher.combine(address)
        }
    }
}
