//
//  CoordinatorableViewModel.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/2/14.
//

import Foundation

extension CoordinatorView {
    class CoordinatorableViewModel: Hashable, Identifiable, CustomStringConvertible {
        var description: String { "\(modelType) at \(address)" }
        let id: String

        let viewModel: DLViewModel
        let modelType: String
        let address: String

        init(viewModel: DLViewModel) {
            self.viewModel = viewModel
            self.modelType = String(describing: type(of: viewModel).self)
            self.address = "\(Unmanaged<AnyObject>.passUnretained(viewModel).toOpaque())"

            if let viewModel = viewModel as? (any Identifiable) {
                self.id = "\(viewModel.id)"
            } else {
                self.id = "\(modelType) at \(address)"
            }
        }

        static func == (lhs: CoordinatorableViewModel, rhs: CoordinatorableViewModel) -> Bool {
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
