import Foundation

public protocol AnySideEffect {
    var queue: DispatchQueue? { get }
    var async: Bool { get }

    var hooks: [AnyUpdater.Type]? { get }

    func condition(box: Any) -> Bool

    func execute(box: Any, trunk: Trunk, interactor: Any)
}

public protocol SideEffect: AnySideEffect {
    associatedtype SStateType
    associatedtype Interactor

    var hooks: [AnyUpdater.Type]? { get }

    func condition(box: StateBox<SStateType>) -> Bool

    func execute(box: StateBox<SStateType>, trunk: Trunk, interactor: Interactor)
}

public extension SideEffect {
    var queue: DispatchQueue? { nil }
    var async: Bool { true }

    var hooks: [AnyUpdater.Type]? { nil }

    func condition(box: Any) -> Bool {
        return condition(box: box as! StateBox<SStateType>)
    }

    func execute(box: Any, trunk: Trunk, interactor: Any) {
        execute(box: box as! StateBox<SStateType>, trunk: trunk, interactor: interactor as! Interactor)
    }
}

public class InteractorLogger {
    static var consoleLogger = ConsoleLogger()

    public static var loggingExcludedSideEffects = [AnySideEffect.Type]()

    public static var logger: ((AnySideEffect) -> Void)? = { sideEffect in

        #if DEBUG
            if loggingExcludedSideEffects.first(where: { $0 == type(of: sideEffect) }) == nil {
                print("---SE---", to: &consoleLogger)
                dump(sideEffect, to: &consoleLogger, maxItems: 20)
                print(".", to: &consoleLogger)
                consoleLogger.flush()
            }
        #endif
    }
}

class ConsoleLogger: TextOutputStream {
    var buffer = ""

    func flush() {
        print(buffer)
        buffer = ""
    }

    func write(_ string: String) {
        buffer += string
    }
}

protocol SideEffectProcessor {
    associatedtype State: StateType

    func processSideEffect(sideEffect: AnySideEffect, box: StateBox<State>)
}

open class Interactor<State: StateType>: StateSubscriber, SideEffectSubscriber, Trunk, SideEffectProcessor {
    private var store: Store<State>
    public var storeTrunk: StoreTrunk { store }
    public var state: State { store.state }

    open var sideEffects: [AnySideEffect] { [] }

    public init(store: Store<State>) {
        self.store = store

        var subscribeInteractor = false
        for sideEffect in sideEffects {
            guard let hooks = sideEffect.hooks else {
                subscribeInteractor = true
                continue
            }
            for hook in hooks {
                store.sideEffectSubscribe(self,
                                          action: String(reflecting: hook),
                                          sideEffectKey: key(sideEffect: sideEffect))
            }
        }

        if subscribeInteractor {
            store.stateSubscribe(self)
        }

        onInit()
    }

    open func onInit() {
    }

    deinit {
        store.unsubscribe(self)
    }

    public func stateChanged(box: StateBox<State>) {
        if condition(box: box) {
            for sideEffect in sideEffects {
                guard sideEffect.hooks == nil else { continue }

                processSideEffect(sideEffect: sideEffect, box: box)
            }
        }
    }

    public func stateChanged(sideEffectKey: String, box: StateBox<State>) {
        for sideEffect in sideEffects {
            guard sideEffectKey == key(sideEffect: sideEffect) else { continue }
            processSideEffect(sideEffect: sideEffect, box: box)
            return
        }
    }

    public func processSideEffect(sideEffect: AnySideEffect, box: StateBox<State>) {
        if sideEffect.condition(box: box) {
            InteractorLogger.logger?(sideEffect)

            if sideEffect.queue == nil {
                sideEffect.execute(box: box, trunk: self, interactor: self)
            } else {
                if sideEffect.async {
                    sideEffect.queue?.async {
                        sideEffect.execute(box: box, trunk: self, interactor: self)
                    }
                } else {
                    sideEffect.queue?.sync {
                        sideEffect.execute(box: box, trunk: self, interactor: self)
                    }
                }
            }
        }
    }

    open func condition(box: Any) -> Bool {
        return true
    }

    func key(sideEffect: AnySideEffect) -> String {
        String(reflecting: sideEffect)
    }
}
