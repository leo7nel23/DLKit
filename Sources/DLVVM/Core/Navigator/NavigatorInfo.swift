//
//  NavigatorInfo.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/6/11.
//

import Foundation

extension DLVVM {

    struct NavigatorInfo: Hashable, Identifiable {
        var description: String { "\(modelType) at \(address)" }

        let id: String

        let viewModel: any DLViewModelProtocol
        let modelType: String
        let address: String

        init(viewModel: any DLViewModelProtocol) {
            if let id = (viewModel as? (any Identifiable))?.id as? String {
                self.id = id
            } else {
                self.id = UUID().uuidString
            }
            self.viewModel = viewModel
            self.modelType = String(describing: type(of: viewModel).self)
            self.address = "\(Unmanaged<AnyObject>.passUnretained(viewModel).toOpaque())"
        }

        static func == (lhs: NavigatorInfo, rhs: NavigatorInfo) -> Bool {
            let lhsType = type(of: lhs.viewModel)
            let rhsType = type(of: rhs.viewModel)
            guard  lhsType == rhsType else { return false }

            return lhs.hashValue == rhs.hashValue
        }

        func hash(into hasher: inout Hasher) {
            if let hashable = viewModel as? (any Hashable) {
                hasher.combine(hashable)
            } else {
                hasher.combine(modelType)
                hasher.combine(address)
            }
        }
    }
}
