//
//  DLManipulation.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/2/5.
//

import Foundation

public protocol DLManipulation {
    associatedtype Manipulation

    func manipulate(_ manipulation: Manipulation)
}
