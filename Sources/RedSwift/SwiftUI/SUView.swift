import SwiftUI
import UIKit


public protocol SUView: View where Nav: NavModel, Presenter: ObservablePresenter {
    associatedtype Nav
    associatedtype Presenter
    
    var navProps: Nav? { get }
    
    init(presenter: Presenter)
}

extension SUView {
    var vc: UIViewController { SUVC(self) }
    
    public static func assembly(
        store: GraphStore,
        setupPresenter: ((Presenter) -> Void)? = nil,
        setupVC: ((UIViewController) -> Void)? = nil
    ) -> UIViewController {
        
        let presenter = Presenter(store: store)
        setupPresenter?(presenter)
        let vc = Self.init(presenter: presenter).vc
        vc.modalPresentationStyle = .overFullScreen
        setupVC?(vc)
        
        return vc
    }
}
