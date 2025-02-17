//
//  ExternallyMutable.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/2/5.
//

import Foundation

public typealias ExternallyMutable = DLVVM.ExternallyMutable

public extension DLVVM {
    @MainActor
    protocol ExternallyMutable {
        associatedtype Manipulation
        
        func manipulate(_ manipulation: Manipulation)
    }
}
