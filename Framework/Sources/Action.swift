import Foundation

public protocol Dispatchable { }

public protocol Action: Dispatchable { }

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

        self.updateState(&typedBox.ref.val)
    }
}

public protocol ThrottleAction {
    
    var interval: TimeInterval { get }
}

public extension ThrottleAction {
    
    var interval: TimeInterval {
        0.3
    }
}
