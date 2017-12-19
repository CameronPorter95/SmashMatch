//
//  MainMenuViewController.swift
//  CookieCrunch
//
//  Created by Cameron Porter on 19/12/17.
//  Copyright © 2017 Cameron Porter. All rights reserved.
//

import UIKit

class MainMenuViewController: UIViewController {
    
    @IBOutlet weak var livesCounter: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
         let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.touchedLives(sender:)))
        livesCounter.addGestureRecognizer(tapGesture)
    }
    
    @objc func touchedLives(sender: UITapGestureRecognizer) {
        print("touched the lives")
    }
    
    func someAction(sender:UITapGestureRecognizer){
        // do other task
    }
    
    // or for Swift 3
    func someAction(_ sender:UITapGestureRecognizer){
        // do other task
    }
}
