//
//  View+Utils.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/2/17.
//

import SwiftUI

public struct RandomBackground: ViewModifier {
    public enum Mode {
        case light
        case dark
        case random
    }
    let backgroundColor: Color

    init(mode: Mode = .light) {
        let (from, to) = { () -> (Double, Double) in
            switch mode {
                case .light:
                    (0.5, 1)

                case .dark:
                    (0, 0.5)

                case .random:
                    (0, 1)
            }
        }()

        backgroundColor = Color(
            red: .random(in: from...to),
            green: .random(in: from...to),
            blue: .random(in: from...to)
        )
    }

    public func body(content: Content) -> some View {
        content
            .background(backgroundColor)
    }
}

/// 讓所有 `View` 都支援 `.randomBackground()`
public extension View {
    func randomBackground(mode: RandomBackground.Mode = .light) -> some View {
        self.modifier(RandomBackground(mode: mode))
    }

    func debugBackground(mode: RandomBackground.Mode = .light) -> some View {
        #if DEBUG
        self.modifier(RandomBackground(mode: mode))
        #else
        self
        #endif
    }
}
