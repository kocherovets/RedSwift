public protocol StoreSubscriberType { }

public protocol AnyStateSubscriber: class, StoreSubscriberType {
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
//
//class StateSubscriptionBox<State>: Hashable {
//    private let originalSubscription: StateSubscription<State>
//    weak var subscriber: AnyStateSubscriber?
//    private let objectIdentifier: ObjectIdentifier
//
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(objectIdentifier)
//    }
//
//    init(
//        originalSubscription: StateSubscription<State>,
//        subscriber: AnyStateSubscriber
//    ) {
//        self.originalSubscription = originalSubscription
//        self.subscriber = subscriber
//        objectIdentifier = ObjectIdentifier(subscriber)
//
//        originalSubscription.observer = { [unowned self] box in
//            self.subscriber?.stateChanged(box: box)
//        }
//    }
//
//    func newValues(box: StateBox<State>) {
//        originalSubscription.newValues(box: box)
//    }
//
//    static func == (left: StateSubscriptionBox<State>, right: StateSubscriptionBox<State>) -> Bool {
//        return left.objectIdentifier == right.objectIdentifier
//    }
//}
//
//public class StateSubscription<State> {
//    public init(sink: @escaping (@escaping (StateBox<State>) -> Void) -> Void) {
//        sink { box in
//            self.newValues(box: box)
//        }
//    }
//
//    public var observer: ((StateBox<State>) -> Void)?
//
//    init() { }
//
//    func newValues(box: StateBox<State>) {
//        observer?(box)
//    }
//}
