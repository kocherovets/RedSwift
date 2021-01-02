//
//  Store.swift
//  RedSwift
//
//  Created by Dmitry Kocherovets on 10.11.2019.
//  Copyright © 2019 Dmitry Kocherovets. All rights reserved.
//

import Foundation
import Framework

func delay(_ delay: Double, closure: @escaping () -> Void) {
    let when = DispatchTime.now() + delay
    DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
}

struct TestState: StateType, Equatable {
    var companyName: String = "test"
}

struct St: StateType, Equatable {
    var test = TestState()
    var counter = CounterState()
    var legacy = LegacyState()
}

class APIManager {
    func test(_ callback: @escaping (Int) -> Void) {
        delay(5) {
            callback(150)
        }
    }
}

protocol AppCounterGraph: GraphType {
    var counter: Int { get }
    func set(counter: Int)
}

protocol AppTestGraph: GraphType {
    var companyName: String { get }
}

struct Graph: Trunk {
    private let store: Store<St>

    var trunk: Trunk { self }
    var storeTrunk: StoreTrunk { store }
    var state: St { store.state }

    init(store: Store<St>) {
        self.store = store
    }
}

extension Graph: AppCounterGraph {
    var counter: Int {
        state.counter.counter
    }

    func set(counter: Int) {
        trunk.dispatch(SetCounterAction(value: counter))
    }
}

extension Graph: AppTestGraph {
    var companyName: String {
        state.test.companyName
    }
}

let storeQueue = DispatchQueue(label: "queueTitle", qos: .userInteractive)

func appReducer(action: Framework.Action, state: St?) -> St {
    return St(
        test: state?.test ?? TestState(),
        counter: state?.counter ?? CounterState(),
        legacy: legacyReducer(action: action, state: state?.legacy)
    )
}

var store = Store<St>(state: St(),
                      queue: storeQueue,
                      middleware: [
                          LoggingMiddleware(loggingExcludedActions: []),
                      ],
                      graph: { store in Graph(store: store) },
                      reducer: appReducer)

class TestStore: Store<St> {
}

typealias Action = ActionWithUpdater
extension Action {
    func updateState(_ state: inout St) { }
}
