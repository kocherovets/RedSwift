//
//  Store.swift
//  ReSwift
//
//  Created by Benjamin Encz on 11/11/15.
//  Copyright © 2015 DigiTales. All rights reserved.
//

import Foundation


fileprivate var _queue: DispatchQueue = DispatchQueue.main
public var StoreQueue: DispatchQueue {
    return _queue
}


/**
 This class is the default implementation of the `Store` protocol. You will use this store in most
 of your applications. You shouldn't need to implement your own store.
 You initialize the store with a reducer and an initial application state. If your app has multiple
 reducers you can combine them by initializng a `MainReducer` with all of your reducers as an
 argument.
 */
open class Store<State: RootStateType>: StoreType, StoreTrunk {    

    typealias SubscriptionType = SubscriptionBox<State>

//    private(set) public var state: State! {
    private(set) public var state: State! {
        didSet {
            subscriptions.forEach {
                if $0.subscriber == nil {
                    subscriptions.remove($0)
                } else {
                    $0.newValues(oldState: oldValue, newState: state)
                }
            }
        }
    }

    let sideEffectDependencyContainer: SideEffectDependencyContainer

    var subscriptions: Set<SubscriptionType> = []

    private var isDispatching = false

    public var dispatchFunction: DispatchFunction!

    /// Indicates if new subscriptions attempt to apply `skipRepeats`
    /// by default.
    fileprivate let subscriptionsAutomaticallySkipRepeats: Bool

    /// Initializes the store with a reducer, an initial state and a list of middleware.
    ///
    /// Middleware is applied in the order in which it is passed into this constructor.
    ///
    /// - parameter reducer: Main reducer that processes incoming actions.
    /// - parameter state: Initial state, if any. Can be `nil` and will be
    ///   provided by the reducer in that case.
    /// - parameter middleware: Ordered list of action pre-processors, acting
    ///   before the root reducer.
    /// - parameter automaticallySkipsRepeats: If `true`, the store will attempt
    ///   to skip idempotent state updates when a subscriber's state type
    ///   implements `Equatable`. Defaults to `true`.
    public required init(
        state: State?,
        queueTitle: String?,
        sideEffectDependencyContainer: SideEffectDependencyContainer,
        middleware: [Middleware<State>] = [],
        automaticallySkipsRepeats: Bool = true
    ) {

        self.sideEffectDependencyContainer = sideEffectDependencyContainer

        if let queueTitle = queueTitle {
            _queue = DispatchQueue(label: queueTitle, qos: .userInteractive)
        }

        self.subscriptionsAutomaticallySkipRepeats = automaticallySkipsRepeats

        // Wrap the dispatch function with all middlewares
        self.dispatchFunction = middleware
            .reversed()
            .reduce(
                { [unowned self] action in
                    self._defaultDispatch(action: action) },
                { dispatchFunction, middleware in
                    // If the store get's deinitialized before the middleware is complete; drop
                    // the action without dispatching.
                    let dispatch: (Dispatchable) -> Void = { [weak self] in self?.dispatch($0) }
                    let getState = { [weak self] in self?.state }
                    return middleware(dispatch, getState)(dispatchFunction)
                })


        self.state = state
    }

    fileprivate func _subscribe<SelectedState, S: StoreSubscriber>
    (
        _ subscriber: S,
        originalSubscription: Subscription<State>,
        transformedSubscription: Subscription<SelectedState>?
    )
    where S.StoreSubscriberStateType == SelectedState
    {
        let subscriptionBox = self.subscriptionBox(originalSubscription: originalSubscription,
                                                   transformedSubscription: transformedSubscription,
                                                   subscriber: subscriber
        )

        subscriptions.update(with: subscriptionBox)

        if let state = self.state {
            originalSubscription.newValues(oldState: nil, newState: state)
        }
    }

    open func subscribe<S: StoreSubscriber>
    (
        _ subscriber: S
    )
    where S.StoreSubscriberStateType == State
    {
        _ = subscribe(subscriber, transform: nil)
    }

    open func subscribe<SelectedState, S: StoreSubscriber>
    (
        _ subscriber: S,
        transform: ((Subscription<State>) -> Subscription<SelectedState>)?
    )
    where S.StoreSubscriberStateType == SelectedState
    {
        // Create a subscription for the new subscriber.
        let originalSubscription = Subscription<State>()
        // Call the optional transformation closure. This allows callers to modify
        // the subscription, e.g. in order to subselect parts of the store's state.
        let transformedSubscription = transform?(originalSubscription)

        _subscribe(subscriber, originalSubscription: originalSubscription,
                   transformedSubscription: transformedSubscription)
    }

    func subscriptionBox<T>
    (
        originalSubscription: Subscription<State>,
        transformedSubscription: Subscription<T>?,
        subscriber: AnyStoreSubscriber
    )
        -> SubscriptionBox<State>
    {
        return SubscriptionBox(
            originalSubscription: originalSubscription,
            transformedSubscription: transformedSubscription,
            subscriber: subscriber
        )
    }

    // swiftlint:disable:next identifier_name
    open func _defaultDispatch(action: Dispatchable) {
        guard !isDispatching else {
            raiseFatalError(
                "ReSwift:ConcurrentMutationError- Action has been dispatched while" +
                    " a previous action is action is being processed. A reducer" +
                    " is dispatching an action, or ReSwift is used in a concurrent context" +
                    " (e.g. from multiple threads)."
            )
        }

        isDispatching = true

        StoreQueue.async { [weak self] in

            guard let self = self else { fatalError() }

            switch action {
            case let action as AnyAction:
                self.state = action.updatedState(currentState: self.state) as? State
            case let sideEffect as AnySideEffect:
                sideEffect.sideEffect(state: self.state,
                                      trunk: SideEffectTrunk(storeTrunk: self),
                                      dependencies: self.sideEffectDependencyContainer)
            default:
                break
            }
        }

        isDispatching = false
    }

    open func dispatch(_ action: Dispatchable,
                       file: String = #file,
                       function: String = #function,
                       line: Int = #line) {

        switch action {
        case _ as AnyAction:
            print("---ACTION---")
        case _ as AnySideEffect:
            print("---SIDE EFFECT---")
        default:
            print("---MIDDLEWARE---")
        }
        print("\(action)")
        print("file: \(file)")
        print("function: \(function)")
        print("line: \(line)")
        print(".")
        print("CounterState.swift:53")

        dispatchFunction(action)
    }

    public typealias DispatchCallback = (State) -> Void
}

// MARK: Skip Repeats for Equatable States

public protocol StoreProvider {

    func subscribe<RootState, SelectedState, Subscriber>
    (
        _ subscriber: Subscriber,
        keyPath: KeyPath<RootState, SelectedState>?
    )
    where RootState: RootStateType,
        SelectedState: Equatable,
        SelectedState == Subscriber.StoreSubscriberStateType,
        Subscriber: StoreSubscriber

    func unsubscribe(_ subscriber: AnyStoreSubscriber)
}

extension Store: StoreProvider {

    open func subscribe<RootState, SelectedState, Subscriber>
    (
        _ subscriber: Subscriber,
        keyPath: KeyPath<RootState, SelectedState>?
    )
    where RootState: RootStateType,
        SelectedState: Equatable,
        SelectedState == Subscriber.StoreSubscriberStateType,
        Subscriber: StoreSubscriber
    {
        let originalSubscription = Subscription<State>()

        var transformedSubscription: Subscription<SelectedState>? = nil
        if let keyPath = keyPath {
            transformedSubscription = originalSubscription.select(keyPath: keyPath as! KeyPath<State, SelectedState>)
        }
        if subscriptionsAutomaticallySkipRepeats {
            transformedSubscription = transformedSubscription?.skipRepeats()
        }
        _subscribe(subscriber,
                   originalSubscription: originalSubscription,
                   transformedSubscription: transformedSubscription)
    }

    open func unsubscribe(_ subscriber: AnyStoreSubscriber) {

        if let index = subscriptions.firstIndex(where: { return $0.subscriber === subscriber }) {
            subscriptions.remove(at: index)
        }
    }
}

public protocol StateProvider {

    func getState<Root: RootStateType, S: StateType>(keyPath: KeyPath<Root, S>) -> S
}

extension Store: StateProvider {

    public func getState<Root: RootStateType, S: StateType>(keyPath: KeyPath<Root, S>) -> S {

        return state[keyPath: keyPath as! KeyPath<State, S>]
    }
}
