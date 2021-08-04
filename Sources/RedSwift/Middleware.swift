public protocol LogMaxItems {
    var logMaxItems: Int { get }
}

public protocol NoLog: LogMaxItems { }

public extension NoLog {
    var logMaxItems: Int { 0 }
}

public enum AfterMiddleware {
    case skip
    case process
}

open class Middleware {
    public init() { }

    open func on(action: Dispatchable,
                 file: String,
                 function: String,
                 line: Int
    ) -> AfterMiddleware {
        .process
    }
}

open class StatedMiddleware<State: StateType> {
    public init() { }

    open func on(action: Dispatchable,
                 state: State,
                 file: String,
                 function: String,
                 line: Int
    ) { }
}

public class LoggingMiddleware: Middleware {
    var consoleLogger = ConsoleLogger()

    var loggingExcludedActions = [Dispatchable.Type]()

    var firstPart: String?
    var startIndex: String.Index?

    public init(loggingExcludedActions: [Dispatchable.Type], firstPart: String? = nil) {
        super.init()
        self.loggingExcludedActions = loggingExcludedActions
        self.firstPart = firstPart
    }

    override public func on(action: Dispatchable,
                            file: String,
                            function: String,
                            line: Int
    ) -> AfterMiddleware {
        #if DEBUG
//            if action is Action {
//                return .process
//            }
            if
                let logMaxItems = (action as? LogMaxItems)?.logMaxItems,
                logMaxItems == 0 {
                return .process
            }

            let printFile: String
            if
                let firstPart = firstPart,
                startIndex == nil {
                let components = file.components(separatedBy: firstPart + "/")
                if
                    let component = components.last {
                    startIndex = file.index(file.endIndex, offsetBy: -component.count - (firstPart + "/").count)
                }
            }
            if let startIndex = startIndex {
                let substring = file[startIndex ..< file.endIndex]
                printFile = String(substring)
            } else {
                printFile = file
            }

            print("---ACTION---", to: &consoleLogger)
            dump(action, to: &consoleLogger, maxItems: (action as? LogMaxItems)?.logMaxItems ?? 20)
            print("file: \(printFile):\(line)", to: &consoleLogger)
            print("function: \(function)", to: &consoleLogger)
            print(".", to: &consoleLogger)
            consoleLogger.flush()
        #endif
        return .process
    }
}
