//
//  AsyncIntercator.swift
//  RedSwift
//
//  Created by Dmitry Kocherovets on 09.05.2020.
//  Copyright © 2020 Dmitry Kocherovets. All rights reserved.
//

import Foundation
import RedSwift

class AsyncInteractor: Interactor<St>
{
    override var sideEffects: [AnySideEffect]
    {
        [
            AsyncSE(),
        ]
    }
}

extension AsyncInteractor
{
    struct AsyncSE: SideEffect
    {
        struct StartAction: Action { }

        func condition(box: StateBox<St>) -> Bool
        {
            box.lastAction is StartAction
        }

        func execute(box: StateBox<St>, trunk: Trunk, interactor: AsyncInteractor)
        {
            delay(5)
            {
                trunk.dispatch(SaveAsyncAction(value: 150))
            }
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
