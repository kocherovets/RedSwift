import Foundation

public typealias Reducer<ReducerStateType> = (_ action: Action, _ state: ReducerStateType?) -> ReducerStateType

open class Store<State: StateType>: StoreTrunk {
    typealias SubscriptionType = SubscriptionBox<State>

    private var reducer: Reducer<State>?

    public var state: State { box.ref.val }

    public private(set) var box: StateBox<State>
    public private(set) var graph: GraphType?

    var subscriptions: Set<SubscriptionType> = []
    var stateSubscriptions: Set<StateSubscriptionBox> = []
//    var stateAndGraphSubscriptions: Set<SubscriptionType> = []
    var graphSubscriptions: Set<GraphSubscriptionBox> = []

    public let queue: DispatchQueue

    private var middleware: [Middleware] = []
    private var statedMiddleware: [StatedMiddleware<State>] = []

    private var throttleActions = [String: TimeInterval]()

    public required init(
        state: State,
        queue: DispatchQueue,
        middleware: [Middleware] = [],
        statedMiddleware: [StatedMiddleware<State>] = [],
        graph: ((Store<State>) -> (GraphType?))? = nil,
        reducer: Reducer<State>? = nil
    ) {
        self.queue = queue
        self.middleware = middleware
        self.statedMiddleware = statedMiddleware
        box = StateBox(state)
        self.graph = graph?(self)
        self.reducer = reducer
    }

    public func graphSubscribe<S: GraphSubscriber>(_ subscriber: S) {
        let subscriptionBox = GraphSubscriptionBox(subscriber: subscriber)

        graphSubscriptions.update(with: subscriptionBox)

        queue.async { [weak self] in
            guard let self = self else { fatalError() }

            if let graph = self.graph {
                subscriber.graphChanged(graph: graph)
            }
        }
    }

    public func subscribe<S: StateSubscriber>(_ subscriber: S) {
        let subscriptionBox = StateSubscriptionBox(subscriber: subscriber)

        stateSubscriptions.update(with: subscriptionBox)

        queue.async { [weak self] in
            guard let self = self else { fatalError() }

            subscriber.stateChanged(box: self.box)
        }
    }

    public func unsubscribe(_ subscriber: StoreSubscriberType) {
        switch subscriber {
        case let subscriber as AnyStateSubscriber:
            if let index = stateSubscriptions.firstIndex(where: { $0.subscriber === subscriber }) {
                stateSubscriptions.remove(at: index)
            }
        case let subscriber as AnyGraphSubscriber:
            if let index = graphSubscriptions.firstIndex(where: { $0.subscriber === subscriber }) {
                graphSubscriptions.remove(at: index)
            }
        default:
            fatalError()
        }
    }

    public func dispatch(_ action: Dispatchable,
                         file: String = #file,
                         function: String = #function,
                         line: Int = #line) {
        if let action = action as? Action {
            queue.async { [weak self] in

                guard let self = self else { fatalError() }

                let oldState = self.box.ref.val
                self.box.ref.val = self.reducer!(action, self.box.state)

                self.box.lastAction = action

                self.subscriptions.forEach {
                    if $0.subscriber == nil {
                        self.subscriptions.remove($0)
                    } else {
                        $0.newValues(oldState: oldState, newState: self.box.ref.val)
                    }
                }
            }
            return
        }

        if let throttleAction = action as? ThrottleAction {
            if
                let interval = throttleActions["\(action)"],
                Date().timeIntervalSince1970 - interval < throttleAction.interval {
                #if DEBUG
                    print("throttleAction \(action)")
                #endif
                return
            }
            throttleActions["\(action)"] = Date().timeIntervalSince1970
        }

        queue.async { [weak self] in

            guard let self = self else { fatalError() }

            for middleware in self.middleware {
                middleware.on(action: action, file: file, function: function, line: line)
            }

            for middleware in self.statedMiddleware {
                middleware.on(action: action, state: self.state, file: file, function: function, line: line)
            }

            switch action {
            case let action as AnyActionWithUpdater:

                action.updateState(box: self.box)

                self.box.lastAction = action

                self.stateSubscriptions.forEach {
                    if $0.subscriber == nil {
                        self.stateSubscriptions.remove($0)
                    } else {
                        $0.subscriber?.stateChanged(box: self.box)
                    }
                }
                if let graph = self.graph {
                    self.graphSubscriptions.forEach {
                        if $0.subscriber == nil {
                            self.graphSubscriptions.remove($0)
                        } else {
                            $0.subscriber?.graphChanged(graph: graph)
                        }
                    }
                }

            default:
                break
            }
        }
    }
}

extension Thread {
    var threadName: String {
        if let currentOperationQueue = OperationQueue.current?.name {
            return "OperationQueue: \(currentOperationQueue)"
        } else if let underlyingDispatchQueue = OperationQueue.current?.underlyingQueue?.label {
            return "DispatchQueue: \(underlyingDispatchQueue)"
        } else {
            let name = __dispatch_queue_get_label(nil)
            return String(cString: name, encoding: .utf8) ?? Thread.current.description
        }
    }
}

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

    public fileprivate(set) var lastAction: Dispatchable?
}

public protocol GraphType {}
