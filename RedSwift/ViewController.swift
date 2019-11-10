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

    var keyPath: KeyPath<State, CounterState> {
        return \.counter
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        store.subscribe(self, keyPath: keyPath)
    }

    func stateChanged(box: StateBox<CounterState>) {

        DispatchQueue.main.async {
            self.companyNameLabel.text = "\(box.state.counter)"

            if box.state.incrementRequested {
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
        store.dispatch(RequestIncrementSE())
    }

}

