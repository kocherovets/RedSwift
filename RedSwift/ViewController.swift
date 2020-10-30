//
//  ViewController.swift
//  RedSwift
//
//  Created by Dmitry Kocherovets on 10.11.2019.
//  Copyright © 2019 Dmitry Kocherovets. All rights reserved.
//

import UIKit

class ViewController: UIViewController, StoreSubscriber {

    @IBOutlet weak var companyNameLabel: UILabel!
    @IBOutlet weak var add1Button: UIButton!
    @IBOutlet weak var add150Button: UIButton!
    @IBOutlet weak var activityIndicatorV: UIActivityIndicatorView!

    var interactor: AsyncInteractor?
    var interactor2: AsyncInteractor2?

    override func viewDidLoad() {
        super.viewDidLoad()

        store.subscribe(self)
        
//        InteractorLogger.loggingExcludedSideEffects = [AsyncInteractor.AsyncSE.self]
        interactor = AsyncInteractor(store: store)
        interactor2 = AsyncInteractor2(store: store)
    }

    func stateChanged(box: StateBox<St>) {

        DispatchQueue.main.async {
            self.companyNameLabel.text = "\(box.state.counter.counter)"

            if box.state.counter.incrementRequested {
                self.activityIndicatorV.startAnimating()
                self.add1Button.isHidden = true
                self.add150Button.isHidden = true
            } else {
                self.activityIndicatorV.stopAnimating()
                self.add1Button.isHidden = false
                self.add150Button.isHidden = false
            }
        }
    }

    @IBAction func addAction1() {
        store.dispatch(IncrementAction())
    }

    @IBAction func addAction150() {
        store.dispatch(AsyncInteractor.AsyncSE.StartAction())
    }

    @IBAction func addAction30() {
        store.dispatch(AsyncInteractor2.AsyncSE.StartAction())
    }

    @IBAction func deleteInteractors() {
        interactor = nil
        interactor2 = nil
    }

}

