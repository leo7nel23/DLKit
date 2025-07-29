# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with the DLVVM framework.

# DLVVM Framework - Architecture Guide

## Framework Overview
DLVVM is a custom SwiftUI reactive MVVM architecture framework designed for complex iOS applications. It provides structured state management, navigation handling, and reactive programming patterns.

## Core Components

### 1. State Protocols

#### BusinessState
Base protocol for all state objects. Used for pure business logic components that don't manage navigation.

```swift
public protocol BusinessState: AnyObject {
    associatedtype R: Reducer where R.State == Self
}
```

**Key Features**:
- Event propagation through `eventSubject`
- Automatic event handling via `fireEvent()`
- Foundation for all state management

#### NavigatableState  
Extends BusinessState for features that can manage navigation flow.

```swift
public protocol NavigatableState: BusinessState {
    associatedtype NavigatorEvent
}
```

**Key Features**:
- Navigation event handling through `NavigatorEvent`
- Route management capabilities
- Support for child state navigation

### 2. Reducer Protocol

Core business logic processing interface:

```swift
public protocol Reducer<State, Action, Event> where State: BusinessState {
    associatedtype State
    associatedtype Action  
    associatedtype Event
    
    func reduce(into state: State, action: Action) -> Procedure<Action, State>
}
```

**Key Features**:
- Immutable state updates
- Effect-based side effect handling through `Procedure`
- Event firing capabilities via `fireEvent()`

### 3. DLView Protocol

SwiftUI view integration protocol:

```swift
public protocol DLView: View {
    associatedtype ReducerState: BusinessState
    typealias Action = ReducerState.R.Action
    typealias ViewModel = DLViewModel<ReducerState>
    
    var viewModel: ViewModel { get }
    init(viewModel: ViewModel)
}
```

**Key Features**:
- Typed action sending via `send()`
- Automatic ViewModel integration
- SwiftUI compatibility

## Architecture Patterns

### Feature Structure Template

```swift
// MARK: - Feature (Reducer)
final class FeatureNameFeature: Reducer {
    @Observable
    final class State: NavigatableState {
        typealias R = FeatureNameFeature
        typealias NavigatorEvent = FeatureNameInternalEvent  // or Void
        
        // Business properties (not optional)
        var data: [DataModel] = []
        var isLoading: Bool = false
        var selectedItem: String? = nil
        
        // Navigation states - only next views are optional
        var nextViewState: NextFeature.State?  // Only for navigation targets
        
        init() {}
    }
    
    enum Event {
        case dataLoaded([DataModel])
        case itemSelected(String)
    }
    
    enum ViewAction {
        case loadData
        case selectItem(String)
        case navigateToNext
    }
    
    enum Action {
        case viewAction(ViewAction)
        case nextView(NextFeature.Event)
    }
    
    func reduce(into state: State, action: Action) -> Procedure<Action, State> {
        switch action {
        case let .viewAction(viewAction):
            return reduce(into: state, with: viewAction)
        case let .nextView(event):
            // Handle child events
            return .none
        }
    }
    
    func reduce(into state: State, with viewAction: ViewAction) -> Procedure<Action, State> {
        switch viewAction {
        case .loadData:
            state.isLoading = true
            return .task {
                let data = await loadDataFromAPI()
                return .dataLoaded(data)
            }
            
        case let .selectItem(id):
            state.selectedItem = id
            fireEvent(.itemSelected(id), with: state)
            return .none
            
        case .navigateToNext:
            // Only navigation target states are optional
            state.nextViewState = NextFeature.State()
            route(
                childState: \.nextViewState,
                to: Action.nextView,
                reducer: NextFeature(),
                routeStyle: .push,
                with: state
            )
            return .none
        }
    }
}
```

### View Structure Template

```swift
// MARK: - View
struct FeatureNameView: DLView {
    @State var viewModel: ViewModelOf<FeatureNameFeature>
    
    var body: some View {
        contentView
            .navigationTitle("Feature Name")
            .toolbar {
                toolbarContent
            }
            .onAppear {
                send(.viewAction(.loadData))
            }
    }
    
    // MARK: - Private Views
    
    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading {
            loadingView
        } else {
            mainContentView
        }
    }
    
    @ViewBuilder
    private var mainContentView: some View {
        List(viewModel.data, id: \.id) { item in
            itemRow(item)
        }
    }
    
    @ViewBuilder
    private func itemRow(_ item: DataModel) -> some View {
        HStack {
            Text(item.title)
            Spacer()
            if viewModel.selectedItem == item.id {
                Image(systemName: "checkmark")
                    .foregroundColor(.accentColor)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            send(.viewAction(.selectItem(item.id)))
        }
    }
    
    @ViewBuilder
    private var loadingView: some View {
        ProgressView("Loading...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button("Next") {
                send(.viewAction(.navigateToNext))
            }
            .disabled(viewModel.selectedItem == nil)
        }
    }
}

#Preview {
    FeatureNameView(
        viewModel: .init(
            initialState: .init(),
            reducer: FeatureNameFeature()
        )
    )
}
```

## Navigation Patterns

### Route Style Guidelines

**RouteStyle Options**:
- `.push`: Standard navigation stack push (most common)
- `.present`: Modal presentation
- `.replace`: Replace current state

### Navigation Implementation

#### Standard Child Navigation
```swift
// Navigation to child feature
case .navigateToChild:
    state.childViewState = ChildFeature.State()  // Only target view is optional
    route(
        childState: \.childViewState,
        to: Action.child,
        reducer: ChildFeature(),
        routeStyle: .push,
        with: state
    )
    return .none
```

#### Cross-Module Navigation
```swift
// Navigation to external module
case .navigateToModule:
    state.moduleViewState = AppCoordinator.makeModuleState()
    route(
        childState: \.moduleViewState,
        container: AppCoordinator.makeModuleStateContainer(),
        to: Action.module,
        routeStyle: .push,
        with: state
    )
    return .none
```

## State Management Best Practices

### State Property Guidelines

1. **Business Properties**: Never optional unless semantically required
   ```swift
   var items: [Item] = []           // ✅ Not optional
   var selectedIndex: Int = 0       // ✅ Not optional  
   var searchText: String = ""      // ✅ Not optional
   var isLoading: Bool = false      // ✅ Not optional
   ```

2. **Navigation States**: Only optional for navigation targets
   ```swift
   var detailViewState: DetailFeature.State?  // ✅ Optional (navigation target)
   var settingsViewState: SettingsFeature.State?  // ✅ Optional (navigation target)
   ```

3. **Component States**: Not optional when embedded
   ```swift
   var tabBarState: TabBarFeature.State = .init()  // ✅ Not optional (always present)
   var headerState: HeaderFeature.State = .init()  // ✅ Not optional (always present)
   ```

### Event Flow Patterns

#### Action Processing
```swift
// 1. ViewAction from UI
Button("Submit") {
    send(.viewAction(.submit))
}

// 2. Process in reducer
case .submit:
    state.isSubmitting = true
    fireEvent(.submissionStarted, with: state)
    return .task {
        await submitData()
        return .submissionCompleted
    }

// 3. Handle completion
case .submissionCompleted:
    state.isSubmitting = false
    fireEvent(.submissionSuccessful, with: state)
    return .none
```

#### Parent-Child Communication
```swift
// Child fires event
fireEvent(.dataChanged(newData), with: state)

// Parent handles child event
case let .childFeature(childEvent):
    switch childEvent {
    case let .dataChanged(data):
        state.parentData = data
        return .none
    }
```

## Component Integration

### NavigationFlow Setup
```swift
extension AppCoordinator {
    static let featureFlow = NavigationFlow(
        stateTypeList: [
            FirstFeature.State.self,
            SecondFeature.State.self
        ],
        viewBuilder: { viewModel in
            switch viewModel {
            case let viewModel as DLViewModel<FirstFeature.State>:
                FirstView(viewModel: viewModel)
            case let viewModel as DLViewModel<SecondFeature.State>:
                SecondView(viewModel: viewModel)
            default:
                nil
            }
        },
        eventHandler: { event in
            return FeatureEvent.fromInternal(event)
        }
    )
}
```

## Testing Patterns

### Feature Testing
```swift
@Test
func testFeatureLogic() {
    let feature = FeatureNameFeature()
    let state = FeatureNameFeature.State()
    
    let procedure = feature.reduce(
        into: state,
        action: .viewAction(.loadData)
    )
    
    #expect(state.isLoading == true)
    // Test effects and state changes
}
```

### View Testing
```swift
#Preview("Loading State") {
    let state = FeatureNameFeature.State()
    state.isLoading = true
    
    return FeatureNameView(
        viewModel: .init(
            initialState: state,
            reducer: FeatureNameFeature()
        )
    )
}
```

## Advanced Patterns

### Procedure Effects
```swift
// Task effect for async operations
return .task {
    let result = await asyncOperation()
    return .operationCompleted(result)
}

// Timer effect
return .timer(interval: 1.0) {
    .timerTick
}

// Combine effect
return .publisher {
    somePublisher
        .map { .publisherUpdate($0) }
        .eraseToAnyPublisher()
}
```

### Error Handling
```swift
enum ViewAction {
    case retry
    case handleError(Error)
}

case let .handleError(error):
    state.errorMessage = error.localizedDescription
    state.showError = true
    return .none
```

## Framework Integration Guidelines

### Dependency Injection
- Use environment objects for shared dependencies
- Pass services through Feature initializers when needed
- Avoid global singletons for testability

### Performance Optimization
- Use `@Observable` for reactive updates
- Minimize state property updates
- Batch related state changes

### Debugging
- Use clear action naming for debug logs
- Implement state snapshots for testing
- Log navigation events for flow debugging

This framework provides a robust foundation for building complex, maintainable SwiftUI applications with clear separation of concerns and predictable state management.