public protocol StoreSubscriberType { }

public protocol AnyStateSubscriber: AnyObject, StoreSubscriberType {
    func stateChanged(box: Any)
}

public protocol StateSubscriber: AnyStateSubscriber {
    associatedtype StateSubscriberStateType

    func stateChanged(box: StateBox<StateSubscriberStateType>)
}

extension StateSubscriber {
    public func stateChanged(box: Any) {
        if let typedBox = box as? StateBox<StateSubscriberStateType> {
            stateChanged(box: typedBox)
        }
    }
}

class StateSubscriptionBox: Hashable {
    weak var subscriber: AnyStateSubscriber?
    private let objectIdentifier: ObjectIdentifier

    func hash(into hasher: inout Hasher) {
        hasher.combine(objectIdentifier)
    }

    init(subscriber: AnyStateSubscriber) {
        self.subscriber = subscriber
        objectIdentifier = ObjectIdentifier(subscriber)
    }

    static func == (left: StateSubscriptionBox, right: StateSubscriptionBox) -> Bool {
        return left.objectIdentifier == right.objectIdentifier
    }
}
