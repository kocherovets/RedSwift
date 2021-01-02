public protocol SideEffectSubscriberType { }

public protocol AnySideEffectSubscriber: class, SideEffectSubscriberType {
    func stateChanged(sideEffectKey: String, box: Any)
}

public protocol SideEffectSubscriber: AnySideEffectSubscriber {
    associatedtype SideEffectSubscriberStateType

    func stateChanged(sideEffectKey: String, box: StateBox<SideEffectSubscriberStateType>)
}

extension SideEffectSubscriber {
    public func stateChanged(sideEffectKey: String, box: Any) {
        if let typedBox = box as? StateBox<SideEffectSubscriberStateType> {
            stateChanged(sideEffectKey: sideEffectKey, box: typedBox)
        }
    }
}

class SideEffectSubscriptionBox: Hashable {
    weak var subscriber: AnySideEffectSubscriber?
    private let objectIdentifier: ObjectIdentifier
    let sideEffectKey: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(objectIdentifier)
    }

    init(subscriber: AnySideEffectSubscriber, sideEffectKey: String) {
        self.subscriber = subscriber
        self.sideEffectKey = sideEffectKey
        objectIdentifier = ObjectIdentifier(subscriber)
    }

    static func == (left: SideEffectSubscriptionBox, right: SideEffectSubscriptionBox) -> Bool {
        return left.objectIdentifier == right.objectIdentifier
    }
}
