//
//  NavigationFlowBuilder.swift
//  DLKit
//
//  Created for NavigationFlow ResultBuilder support
//

import Foundation
import SwiftUI

public extension DLVVM {
    /// ResultBuilder 用於建構 NavigationFlow
    /// 提供 DSL 語法來簡化 NavigationFlow 的建立
    @resultBuilder
    struct NavigationFlowBuilder {
        
        /// 建構單一 View 類型
        public static func buildBlock<V: DLView>(_ view: V.Type) -> [ViewTypeDescriptor] 
        where V.ReducerState: NavigatableState {
            [ViewTypeDescriptor(view)]
        }
        
        /// 建構多個 View 類型
        public static func buildBlock(_ views: ViewTypeDescriptor...) -> [ViewTypeDescriptor] {
            views
        }
        
        /// 建構 View 類型陣列
        public static func buildArray(_ components: [[ViewTypeDescriptor]]) -> [ViewTypeDescriptor] {
            components.flatMap { $0 }
        }
        
        /// 支援條件語句
        public static func buildEither(first component: [ViewTypeDescriptor]) -> [ViewTypeDescriptor] {
            component
        }
        
        /// 支援條件語句
        public static func buildEither(second component: [ViewTypeDescriptor]) -> [ViewTypeDescriptor] {
            component
        }
        
        /// 支援可選內容
        public static func buildOptional(_ component: [ViewTypeDescriptor]?) -> [ViewTypeDescriptor] {
            component ?? []
        }
        
        /// 建構單一元素（將 View 類型轉換為 ViewTypeDescriptor）
        public static func buildExpression<V: DLView>(_ view: V.Type) -> ViewTypeDescriptor
        where V.ReducerState: NavigatableState {
            ViewTypeDescriptor(view)
        }
        
        /// 建構已存在的 ViewTypeDescriptor
        public static func buildExpression(_ descriptor: ViewTypeDescriptor) -> ViewTypeDescriptor {
            descriptor
        }
    }
}

/// 便利類型別名
public typealias NavigationFlowBuilder = DLVVM.NavigationFlowBuilder