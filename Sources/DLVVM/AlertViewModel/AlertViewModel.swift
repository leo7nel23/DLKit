//
//  AlertViewModel.swift
//  DLKit
//
//  Created by 賴柏宏 on 2025/2/17.
//

import Foundation
import SwiftUI

public final class AlertViewModel {
    let title: String
    let message: String
    let viewBuilder: () -> any View

    public init(
        title: String,
        message: String,
        viewBuilder: (() -> any View)? = nil
    ) {
        self.title = title
        self.message = message
        self.viewBuilder = viewBuilder ?? {
            Button("OK", role: .none, action: {})
        }
    }
}
