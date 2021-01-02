// MARK: State

public protocol StateType { }

final class Ref<T> {
    var val: T
    init(_ v: T) { val = v }
}

public struct StateBox<T> {
    var ref: Ref<T>

    public init(_ x: T) {
        ref = Ref(x)
    }

    public var state: T { ref.val }

    public internal(set) var lastAction: Dispatchable?
}

// MARK: Graph

public protocol GraphType {}

// MARK: Legacy actions

public protocol Dispatchable { }

public protocol Action: Dispatchable { }

public typealias Reducer<ReducerStateType> = (_ action: Action, _ state: ReducerStateType?) -> ReducerStateType

// MARK: New actions

public protocol AnyActionWithUpdater: Dispatchable {
    func updateState(box: Any)
}

public protocol ActionWithUpdater: AnyActionWithUpdater {
    associatedtype State: StateType

    func updateState(_ state: inout State)
}

public extension ActionWithUpdater {
    func updateState(box: Any) {
        let typedBox = box as! StateBox<State>

        updateState(&typedBox.ref.val)
    }
}

// MARK: Special actions

public protocol ThrottleAction {
    var interval: TimeInterval { get }
}

public extension ThrottleAction {
    var interval: TimeInterval {
        0.3
    }
}

// MARK: Trunk

public protocol StoreTrunk {

    func dispatch(_ action: Dispatchable,
                  file: String,
                  function: String,
                  line: Int)
}

public protocol Trunk {

    var storeTrunk: StoreTrunk { get }

    func dispatch(_ action: Dispatchable,
                  file: String,
                  function: String,
                  line: Int)
}

extension Trunk {

    public func dispatch(_ action: Dispatchable,
                         file: String = #file,
                         function: String = #function,
                         line: Int = #line) {

        storeTrunk.dispatch(action, file: file, function: function, line: line)
    }

}
