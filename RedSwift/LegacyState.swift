import Foundation
import Framework

struct LegacyState: StateType, Equatable {
    public fileprivate(set) var legacyCounter: Int = 0
}

enum LegacyAction: Framework.Action {
    case increment
}

func legacyReducer(action: Framework.Action, state: LegacyState?) -> LegacyState {
    var state = state ?? LegacyState()

    guard let action = action as? LegacyAction else { return state }

    switch action {
    case .increment:
        state.legacyCounter += 1
    }

    return state
}
