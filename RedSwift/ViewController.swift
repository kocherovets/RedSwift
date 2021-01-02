//
//  ViewController.swift
//  RedSwift
//
//  Created by Dmitry Kocherovets on 10.11.2019.
//  Copyright © 2019 Dmitry Kocherovets. All rights reserved.
//

import UIKit

class ViewController: UIViewController, StateSubscriber, GraphSubscriber {
    @IBOutlet var companyNameLabel: UILabel!
    @IBOutlet var add1Button: UIButton!
    @IBOutlet var add150Button: UIButton!
    @IBOutlet var activityIndicatorV: UIActivityIndicatorView!

    var interactor: AsyncInteractor?
    var interactor2: AsyncInteractor2?

    override func viewDidLoad() {
        super.viewDidLoad()

        store.subscribe(self)

        store.graphSubscribe(self)

//        InteractorLogger.loggingExcludedSideEffects = [AsyncInteractor.AsyncSE.self]
        interactor = AsyncInteractor(store: store)
        interactor2 = AsyncInteractor2(store: store)
    }

//    func graphChanged(graph: AppCounterGraph) {
//        print(graph.counter)
//    }

    func graphChanged(graph: AppCounterGraph & AppTestGraph) {
        print(graph.counter)
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
//        (store.graph as! AppCounterGraph).set(counter: 10)
    }

    @IBAction func addAction30() {
        store.dispatch(AsyncInteractor2.AsyncSE.StartAction())
    }

    @IBAction func deleteInteractors() {
        interactor = nil
        interactor2 = nil
    }
}
