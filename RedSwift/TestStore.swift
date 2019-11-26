//
//  Store.swift
//  RedSwift
//
//  Created by Dmitry Kocherovets on 10.11.2019.
//  Copyright © 2019 Dmitry Kocherovets. All rights reserved.
//

import Foundation

func delay(_ delay: Double, closure: @escaping () -> ()) {
    let when = DispatchTime.now() + delay
    DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
}

struct TestState: StateType {
    var companyName: String = "test"
}


struct St: StateType {
    var test = TestState()
    var counter = CounterState()
}

class APIManager {

    func test(_ callback: @escaping (Int) -> Void) {
        delay(5) {
            callback(150)
        }
    }
}

class DependencyContainer: SideEffectDependencyContainer {
    let api = APIManager()
}

var store = Store<St>(state: St(),
                         queueTitle: "queueTitle",
                         sideEffectDependencyContainer: DependencyContainer(),
                         middleware: [])

class TestStore: Store<St> {

}
