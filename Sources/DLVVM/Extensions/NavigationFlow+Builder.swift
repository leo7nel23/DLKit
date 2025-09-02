//
//  NavigationFlow+Builder.swift
//  DLKit
//
//  Created for NavigationFlow ResultBuilder support
//

import Foundation
import SwiftUI

public extension DLVVM.NavigationFlow {
    
    /// 使用 ResultBuilder 初始化 NavigationFlow
    /// - Parameter content: ResultBuilder 閉包，包含要註冊的 View 類型
    /// - Parameter eventHandler: 可選的事件處理器
    @MainActor
    convenience init(
        @NavigationFlowBuilder _ content: () -> [ViewTypeDescriptor],
        eventHandler: ((Any) -> Any?)? = nil
    ) {
        let descriptors = content()
        
        // 提取所有 State 類型
        let stateTypeList = descriptors.map(\.stateType)
        
        // 創建統一的 viewBuilder
        let viewBuilder: CoordinatorViewBuilder = { viewModel in
            // 嘗試每個描述符的 viewBuilder，直到找到匹配的
            for descriptor in descriptors {
                if let view = descriptor.viewBuilder(viewModel) {
                    return view
                }
            }
            return nil
        }
        
        // 使用現有的 designated initializer
        self.init(
            stateTypeList: stateTypeList,
            viewBuilder: viewBuilder,
            eventHandler: eventHandler
        )
    }
}

// 移除全域便利函數，避免命名衝突
// 直接使用 NavigationFlow.init 的 ResultBuilder 版本即可