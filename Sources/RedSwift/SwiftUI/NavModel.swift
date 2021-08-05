import DeclarativeTVC
import UIKit

public protocol NavModel: Equatable {
    var title: String? { get }
    var rightBtn: NavRightBtn? { get }
    func setNavigation(_ nBar: UINavigationBar, _ vcView: UIView)
}

public struct NavRightBtn: Equatable {
    public let icon: UIImage?
    public let reaction: Command

    public init(icon: UIImage?, reaction: Command) {
        self.icon = icon
        self.reaction = reaction
    }
}
