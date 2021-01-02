public protocol AnyGraphSubscriber: class, StoreSubscriberType {
    func graphChanged(graph: Any)
}

public protocol GraphSubscriber: AnyGraphSubscriber {
    associatedtype GraphSubscriberGraphType

    func graphChanged(graph: GraphSubscriberGraphType)
}

extension GraphSubscriber {
    public func graphChanged(graph: Any) {
        if let graph = graph as? GraphSubscriberGraphType {
            graphChanged(graph: graph)
        }
    }
}

class GraphSubscriptionBox: Hashable {
    weak var subscriber: AnyGraphSubscriber?
    private let objectIdentifier: ObjectIdentifier

    func hash(into hasher: inout Hasher) {
        hasher.combine(objectIdentifier)
    }

    init(subscriber: AnyGraphSubscriber) {
        self.subscriber = subscriber
        objectIdentifier = ObjectIdentifier(subscriber)
    }

    static func == (left: GraphSubscriptionBox, right: GraphSubscriptionBox) -> Bool {
        return left.objectIdentifier == right.objectIdentifier
    }
}
