import DeclarativeTVC
import SwiftUI
import UIKit

final class SUVC<SV>: UIHostingController<SV> where SV: SUView {
    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }

    private var navRightBtnReaction: Command?
    private var navModel: SV.Nav?

    init(_ suView: SV) {
        super.init(rootView: suView)

        navModel = suView.navProps
    }

    deinit {
        #if DEBUG
            print("DEINIT \(self)")
        #endif
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        setNavigation(navModel)
    }

    private func setNavigation(_ model: SV.Nav?) {
        guard let nc = navigationController else { return }
        navigationItem.backButtonTitle = ""
        if let navModel = model {
            nc.setNavigationBarHidden(false, animated: true)
            navModel.setNavigation(nc.navigationBar, view)
            setNavItem(navModel)
        } else {
            nc.setNavigationBarHidden(true, animated: true)
        }
    }

    private func setNavItem(_ model: SV.Nav) {
        navigationItem.title = model.title
        navRightBtnReaction = model.rightBtn?.reaction
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: model.rightBtn?.icon,
            style: .plain,
            target: self,
            action: #selector(rightNavBtnAction(_:)))
    }

    @objc private func rightNavBtnAction(_ sender: UIBarButtonItem) {
        navRightBtnReaction?.perform()
    }
}
