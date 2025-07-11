//
//  Coordinator.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/6/11.
//

import Foundation
import SwiftUI

public typealias Coordinator = DLVVM.Coordinator

public extension DLVVM {
    protocol Coordinator {
        associatedtype Destination

        var navigator: Navigator { get }

        func requestTo(_ destination: Destination)
    }
}
