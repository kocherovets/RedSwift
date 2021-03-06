//
//  CounterState.swift
//  RedSwift
//
//  Created by Dmitry Kocherovets on 10.11.2019.
//  Copyright © 2019 Dmitry Kocherovets. All rights reserved.
//

import Foundation
import RedSwift

struct APIError {
}

struct CounterState: StateType, Equatable {

    var counter: Int = 0
    var incrementRequested = false
}

struct IncrementAction: Action, ThrottleAction {

    func updateState(_ state: inout St) {
        state.counter.counter += 1
    }
}

struct AddAction: Action {

    let value: Int

    func updateState(_ state: inout St) {

        state.counter.counter += value
        state.counter.incrementRequested = false
    }
}

struct RequestIncrementAction: Action {

    func updateState(_ state: inout St) {

        state.counter.incrementRequested = true
    }
}

//struct RequestIncrementSE: SideEffect {
//
//    func sideEffect(state: St, trunk: Trunk, dependencies: DependencyContainer) {
//
//        trunk.dispatch(RequestIncrementAction())
//
//        dependencies.api.test { value in
//            trunk.dispatch(AddAction(value: value))
//        }
//    }
//}
