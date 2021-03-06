//
//  SubscriberWrapper.swift
//  ReSwift
//
//  Created by Virgilio Favero Neto on 4/02/2016.
//  Copyright © 2016 Benjamin Encz. All rights reserved.
//

/// A box around subscriptions and subscribers.
///
/// Acts as a type-erasing wrapper around a subscription and its transformed subscription.
/// The transformed subscription has a type argument that matches the selected substate of the
/// subscriber; however that type cannot be exposed to the store.
///
/// The box subscribes either to the original subscription, or if available to the transformed
/// subscription and passes any values that come through this subscriptions to the subscriber.
class SubscriptionBox<State>: Hashable {

    private let originalSubscription: Subscription<State>
    weak var subscriber: AnyStoreSubscriber?
    private let objectIdentifier: ObjectIdentifier

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.objectIdentifier)
    }

    init(
        originalSubscription: Subscription<State>,
        subscriber: AnyStoreSubscriber
    ) {
        self.originalSubscription = originalSubscription
        self.subscriber = subscriber
        self.objectIdentifier = ObjectIdentifier(subscriber)

        originalSubscription.observer = { [unowned self] box in
            self.subscriber?.stateChanged(box: box)
        }
    }

    func newValues(box: StateBox<State>) {
        // We pass all new values through the original subscription, which accepts
        // values of type `<State>`. If present, transformed subscriptions will
        // receive this update and transform it before passing it on to the subscriber.
        self.originalSubscription.newValues(box: box)
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

    // MARK: Public Interface

    /// Initializes a subscription with a sink closure. The closure provides a way to send
    /// new values over this subscription.
    public init(sink: @escaping (@escaping (StateBox<State>) -> Void) -> Void) {
        // Provide the caller with a closure that will forward all values
        // to observers of this subscription.
        sink { box in
            self.newValues(box: box)
        }
    }

    /// The closure called with changes from the store.
    /// This closure can be written to for use in extensions to Subscription similar to `skipRepeats`
    public var observer: ((StateBox<State>) -> Void)?

    // MARK: Internals

    init() { }

    /// Sends new values over this subscription. Observers will be notified of these new values.
    func newValues(box: StateBox<State>) {
        self.observer?(box)
    }
}
