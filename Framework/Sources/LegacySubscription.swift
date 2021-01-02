public protocol AnyStoreSubscriber: AnyObject {
    // swiftlint:disable:next identifier_name
    func _newState(state: Any)
}

public protocol StoreSubscriber: AnyStoreSubscriber {
    associatedtype StoreSubscriberStateType

    func newState(state: StoreSubscriberStateType)
}

extension StoreSubscriber {
    // swiftlint:disable:next identifier_name
    public func _newState(state: Any) {
        if let typedState = state as? StoreSubscriberStateType {
            newState(state: typedState)
        }
    }
}

class SubscriptionBox<State>: Hashable {
    private let originalSubscription: Subscription<State>
    weak var subscriber: AnyStoreSubscriber?
    private let objectIdentifier: ObjectIdentifier

    #if swift(>=5.0)
        func hash(into hasher: inout Hasher) {
            hasher.combine(objectIdentifier)
        }

    #elseif swift(>=4.2)
        #if compiler(>=5.0)
            func hash(into hasher: inout Hasher) {
                hasher.combine(objectIdentifier)
            }
        #else
            var hashValue: Int {
                return objectIdentifier.hashValue
            }
        #endif
    #else
        var hashValue: Int {
            return objectIdentifier.hashValue
        }
    #endif

    init<T>(
        originalSubscription: Subscription<State>,
        transformedSubscription: Subscription<T>?,
        subscriber: AnyStoreSubscriber
    ) {
        self.originalSubscription = originalSubscription
        self.subscriber = subscriber
        objectIdentifier = ObjectIdentifier(subscriber)

        // If we received a transformed subscription, we subscribe to that subscription
        // and forward all new values to the subscriber.
        if let transformedSubscription = transformedSubscription {
            transformedSubscription.observer = { [unowned self] _, newState in
                self.subscriber?._newState(state: newState as Any)
            }
            // If we haven't received a transformed subscription, we forward all values
            // from the original subscription.
        } else {
            originalSubscription.observer = { [unowned self] _, newState in
                self.subscriber?._newState(state: newState as Any)
            }
        }
    }

    func newValues(oldState: State, newState: State) {
        // We pass all new values through the original subscription, which accepts
        // values of type `<State>`. If present, transformed subscriptions will
        // receive this update and transform it before passing it on to the subscriber.
        originalSubscription.newValues(oldState: oldState, newState: newState)
    }

    static func == (left: SubscriptionBox<State>, right: SubscriptionBox<State>) -> Bool {
        return left.objectIdentifier == right.objectIdentifier
    }
}

/// Represents a subscription of a subscriber to the store. The subscription determines which new
/// values from the store are forwarded to the subscriber, and how they are transformed.
/// The subscription acts as a very-light weight signal/observable that you might know from
/// reactive programming libraries.
public class Subscription<State> {
    private func _select<Substate>(
        _ selector: @escaping (State) -> Substate
    ) -> Subscription<Substate> {
        return Subscription<Substate> { sink in
            self.observer = { oldState, newState in
                sink(oldState.map(selector) ?? nil, selector(newState))
            }
        }
    }

    // MARK: Public Interface

    /// Initializes a subscription with a sink closure. The closure provides a way to send
    /// new values over this subscription.
    public init(sink: @escaping (@escaping (State?, State) -> Void) -> Void) {
        // Provide the caller with a closure that will forward all values
        // to observers of this subscription.
        sink { old, new in
            self.newValues(oldState: old, newState: new)
        }
    }

    /// Provides a subscription that selects a substate of the state of the original subscription.
    /// - parameter selector: A closure that maps a state to a selected substate
    public func select<Substate>(
        _ selector: @escaping (State) -> Substate
    ) -> Subscription<Substate> {
        return _select(selector)
    }

    /// Provides a subscription that selects a substate of the state of the original subscription.
    /// - parameter keyPath: A key path from a state to a substate
    public func select<Substate>(
        _ keyPath: KeyPath<State, Substate>
    ) -> Subscription<Substate> {
        return _select { $0[keyPath: keyPath] }
    }

    /// Provides a subscription that skips certain state updates of the original subscription.
    /// - parameter isRepeat: A closure that determines whether a given state update is a repeat and
    /// thus should be skipped and not forwarded to subscribers.
    /// - parameter oldState: The store's old state, before the action is reduced.
    /// - parameter newState: The store's new state, after the action has been reduced.
    public func skipRepeats(_ isRepeat: @escaping (_ oldState: State, _ newState: State) -> Bool)
        -> Subscription<State> {
        return Subscription<State> { sink in
            self.observer = { oldState, newState in
                switch (oldState, newState) {
                case let (old?, new):
                    if !isRepeat(old, new) {
                        sink(oldState, newState)
                    } else {
                        return
                    }
                default:
                    sink(oldState, newState)
                }
            }
        }
    }

    /// The closure called with changes from the store.
    /// This closure can be written to for use in extensions to Subscription similar to `skipRepeats`
    public var observer: ((State?, State) -> Void)?

    // MARK: Internals

    init() {}

    /// Sends new values over this subscription. Observers will be notified of these new values.
    func newValues(oldState: State?, newState: State) {
        observer?(oldState, newState)
    }
}

extension Subscription where State: Equatable {
    public func skipRepeats() -> Subscription<State> {
        return skipRepeats(==)
    }
}

/// Subscription skipping convenience methods
extension Subscription {
    /// Provides a subscription that skips certain state updates of the original subscription.
    ///
    /// This is identical to `skipRepeats` and is provided simply for convenience.
    /// - parameter when: A closure that determines whether a given state update is a repeat and
    /// thus should be skipped and not forwarded to subscribers.
    /// - parameter oldState: The store's old state, before the action is reduced.
    /// - parameter newState: The store's new state, after the action has been reduced.
    public func skip(when: @escaping (_ oldState: State, _ newState: State) -> Bool) -> Subscription<State> {
        return skipRepeats(when)
    }

    /// Provides a subscription that only updates for certain state changes.
    ///
    /// This is effectively the inverse of `skip(when:)` / `skipRepeats(:)`
    /// - parameter when: A closure that determines whether a given state update should notify
    /// - parameter oldState: The store's old state, before the action is reduced.
    /// - parameter newState: The store's new state, after the action has been reduced.
    /// the subscriber.
    public func only(when: @escaping (_ oldState: State, _ newState: State) -> Bool) -> Subscription<State> {
        return skipRepeats { oldState, newState in
            !when(oldState, newState)
        }
    }
}

extension Store {
    fileprivate func _subscribe<SelectedState, S: StoreSubscriber>(
        _ subscriber: S, originalSubscription: Subscription<State>,
        transformedSubscription: Subscription<SelectedState>?)
        where S.StoreSubscriberStateType == SelectedState
    {
        let subscriptionBox = self.subscriptionBox(
            originalSubscription: originalSubscription,
            transformedSubscription: transformedSubscription,
            subscriber: subscriber
        )

        subscriptions.update(with: subscriptionBox)

//        if let state = self.state {
        originalSubscription.newValues(oldState: nil, newState: state)
//        }
    }

    open func subscribe<S: StoreSubscriber>(_ subscriber: S)
        where S.StoreSubscriberStateType == State {
        subscribe(subscriber, transform: nil)
    }

    open func subscribe<SelectedState, S: StoreSubscriber>(
        _ subscriber: S, transform: ((Subscription<State>) -> Subscription<SelectedState>)?
    ) where S.StoreSubscriberStateType == SelectedState {
        // Create a subscription for the new subscriber.
        let originalSubscription = Subscription<State>()
        // Call the optional transformation closure. This allows callers to modify
        // the subscription, e.g. in order to subselect parts of the store's state.
        let transformedSubscription = transform?(originalSubscription)

        _subscribe(subscriber, originalSubscription: originalSubscription,
                   transformedSubscription: transformedSubscription)
    }

    func subscriptionBox<T>(
        originalSubscription: Subscription<State>,
        transformedSubscription: Subscription<T>?,
        subscriber: AnyStoreSubscriber
    ) -> SubscriptionBox<State> {
        return SubscriptionBox(
            originalSubscription: originalSubscription,
            transformedSubscription: transformedSubscription,
            subscriber: subscriber
        )
    }

    open func unsubscribe(_ subscriber: AnyStoreSubscriber) {
        #if swift(>=5.0)
            if let index = subscriptions.firstIndex(where: { $0.subscriber === subscriber }) {
                subscriptions.remove(at: index)
            }
        #else
            if let index = subscriptions.index(where: { $0.subscriber === subscriber }) {
                subscriptions.remove(at: index)
            }
        #endif
    }
}
