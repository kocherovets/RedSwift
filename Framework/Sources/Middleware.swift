//
//  Middleware.swift
//  ReSwift
//
//  Created by Benji Encz on 12/24/15.
//  Copyright © 2015 Benjamin Encz. All rights reserved.
//

public typealias DispatchFunction = (Dispatchable) -> Void

open class Middleware {

    public init() { }

    open func on(action: Dispatchable,
                 file: String,
                 function: String,
                 line: Int
    ) {

    }
}

open class StatedMiddleware<State: RootStateType> {

    public init() { }

    open func on(action: Dispatchable,
                 state: State,
                 file: String,
                 function: String,
                 line: Int
    ) {

    }
}


public class LoggingMiddleware: Middleware {

    var loggingExcludedActions = [Dispatchable.Type]()

    public init(loggingExcludedActions: [Dispatchable.Type]) {

        super.init()
        self.loggingExcludedActions = loggingExcludedActions
    }

    public override func on(action: Dispatchable,
                            file: String,
                            function: String,
                            line: Int) {

        if loggingExcludedActions.first(where: { $0 == type(of: action) }) == nil {

            print("---ACTION---")
            dump(action)
            print("file: \(file):\(line)")
            print("function: \(function)")
            print(".")
        }
    }
}
