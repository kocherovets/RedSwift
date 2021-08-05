import Combine
import Foundation


public protocol SUProps: Equatable {
    static var zero: Self { get }
}

public protocol ObservablePresenter: ObservableObject {
    init(store: GraphStore)
}

open class SUPresenter<Graph, Props>: ObservablePresenter, GraphSubscriber where Props: SUProps {

    public let store: GraphStore
    @Published public var props: Props = .zero
    
    public var box = Set<AnyCancellable>()
    private var firstPass = true

    required public init(store: GraphStore) {
        self.store = store
        subscribe()
        onInit()
    }

    deinit {
        unsubscribe()
        onDeinit()
    }
    
    private func onInit() {
        if let graph = store.graph as? Graph {
            onInit(graph: graph)
        }
    }

    private func onDeinit() {
        if let graph = store.graph as? Graph {
            onDeinit(graph: graph)
        }
    }

    open func onInit(graph: Graph) { }
    open func onDeinit(graph: Graph) { }
    
    public final func graphChanged(graph: Graph) {
        func update() {
            if react(for: graph) || firstPass {
                firstPass = false
                DispatchQueue.main.async {
                    self.updateProps(for: graph)
                }
            } else {
                return
            }
        }
        
        if firstPass || Thread.current.threadName == store.queue.label {
            update()
        } else {
            store.queue.async {
                update()
            }
        }
    }

    private func subscribe() {
        #if DEBUG
        print("subscribe presenter \(type(of: self))")
        #endif
        
        store.graphSubscribe(self)
    }

    private func unsubscribe() {
        box.forEach { item in item.cancel() }
        box = []
        store.unsubscribe(self)
        
        #if DEBUG
        print("unsubscribe presenter \(type(of: self)), \(box)")
        #endif
    }

    open func react(for graph: Graph) -> Bool { true }
    
    open func updateProps(for graph: Graph) { }
}
