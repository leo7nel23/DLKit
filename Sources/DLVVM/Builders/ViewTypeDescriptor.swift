//
//  ViewTypeDescriptor.swift
//  DLKit
//
//  Created for NavigationFlow ResultBuilder support
//

import Foundation
import SwiftUI

public extension DLVVM {
    /// 用於描述 View 類型和對應 State 類型的描述符
    /// 採用泛型約束確保編譯時的類型安全
    struct ViewTypeDescriptor {
        let viewType: Any.Type
        let stateType: any NavigatableState.Type
        let viewBuilder: (any DLViewModelProtocol) -> (any View)?
        
        /// 從 DLView 類型創建 ViewTypeDescriptor
        /// - Parameter viewType: 遵循 DLView 協議的 View 類型
        /// 此初始化方法透過泛型約束確保編譯時類型安全
        public init<V: DLView>(_ viewType: V.Type) 
        where V.ReducerState: NavigatableState {
            self.viewType = viewType
            self.stateType = V.ReducerState.self
            
            // 創建類型安全的 view builder
            self.viewBuilder = { viewModel in
                guard let typedViewModel = viewModel as? DLViewModel<V.ReducerState> else {
                    return nil
                }
                return V(viewModel: typedViewModel)
            }
        }
        
        /// 明確指定 State 類型的初始化方法（用於特殊情況）
        public init<V: DLView, S: NavigatableState>(_ viewType: V.Type, stateType: S.Type) 
        where V.ReducerState == S {
            self.viewType = viewType
            self.stateType = stateType
            
            // 創建類型安全的 view builder
            self.viewBuilder = { viewModel in
                guard let typedViewModel = viewModel as? DLViewModel<S> else {
                    return nil
                }
                return V(viewModel: typedViewModel)
            }
        }
    }
}

/// 便利類型別名
public typealias ViewTypeDescriptor = DLVVM.ViewTypeDescriptor

/// 為了支援更簡潔的語法，提供全域便利函數
public func viewDescriptor<V: DLView, S: NavigatableState>(
    _ viewType: V.Type, 
    stateType: S.Type
) -> ViewTypeDescriptor 
where V: View, V.ViewModel.StateType == S {
    return ViewTypeDescriptor(viewType, stateType: stateType)
}