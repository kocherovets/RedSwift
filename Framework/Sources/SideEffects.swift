import Foundation

public protocol StoreTrunk {

    func dispatch(_ action: Dispatchable,
                  file: String,
                  function: String,
                  line: Int)
}

public protocol Trunk {

    var storeTrunk: StoreTrunk { get }

    func dispatch(_ action: Dispatchable,
                  file: String,
                  function: String,
                  line: Int)
}

extension Trunk {

    public func dispatch(_ action: Dispatchable,
                         file: String = #file,
                         function: String = #function,
                         line: Int = #line) {

        storeTrunk.dispatch(action, file: file, function: function, line: line)
    }

}
