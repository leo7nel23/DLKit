//
//  File.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/2/8.
//

import Foundation
import SwiftUI

struct NavigationGestureModifier: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        DispatchQueue.main.async {
            if let navigationController = viewController.navigationController {
                navigationController.interactivePopGestureRecognizer?.isEnabled = true
                navigationController.interactivePopGestureRecognizer?.delegate = nil
            }
        }
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

public extension View {
    func enableSwipeBack() -> some View {
        self.background(NavigationGestureModifier())
    }
}
