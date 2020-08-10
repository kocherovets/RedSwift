//
//  AsyncIntercator.swift
//  RedSwift
//
//  Created by Dmitry Kocherovets on 09.05.2020.
//  Copyright © 2020 Dmitry Kocherovets. All rights reserved.
//

import Foundation

private let serviceQueue = DispatchQueue(label: "AsyncInteractor2", qos: .background, attributes: [.concurrent])

class AsyncInteractor2: Interactor<St>
{
    override var sideEffects: [AnySideEffect]
    {
        [
            AsyncSE(),
        ]
    }
}

protocol QueuedSideEffect: SideEffect {
}

extension QueuedSideEffect {
    var queue: DispatchQueue? { serviceQueue }
}

extension AsyncInteractor2
{
    
    struct StartAction: Action
    {
        func updateState(_ state: inout St)
        {
        }
    }

    struct AsyncSE: QueuedSideEffect
    {
        func condition(box: StateBox<St>) -> Bool
        {
            box.lastAction is StartAction
        }

        func execute(box: StateBox<St>, trunk: Trunk, interactor: AsyncInteractor2)
        {
            sleep(5)
            trunk.dispatch(SaveAsyncAction(value: 30))
        }
    }

    struct SaveAsyncAction: Action
    {
        let value: Int

        func updateState(_ state: inout St)
        {
            state.counter.counter += value
        }
    }
}
