//
//  UIColor+Codable.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/2/5.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

#if canImport(UIKit)
public extension Decodable where Self: UIColor {

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let components = try container.decode([CGFloat].self)
        self = Self.init(red: components[0], green: components[1], blue: components[2], alpha: components[3])
    }
}

public extension Encodable where Self: UIColor {
    func encode(to encoder: Encoder) throws {
        var r, g, b, a: CGFloat
        (r, g, b, a) = (0, 0, 0, 0)
        var container = encoder.singleValueContainer()
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        try container.encode([r,g,b,a])
    }

}

extension UIColor: Codable { }
#endif
