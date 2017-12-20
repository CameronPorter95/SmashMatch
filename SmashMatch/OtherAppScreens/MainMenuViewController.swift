//
//  MainMenuViewController.swift
//  CookieCrunch
//
//  Created by Cameron Porter on 19/12/17.
//  Copyright © 2017 Cameron Porter. All rights reserved.
//

import UIKit
import SQLite
import SQLite3

class MainMenuViewController: UIViewController {
    
    @IBOutlet weak var livesCounter: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        connectToDatabase()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.touchedLives(sender:)))
        livesCounter.addGestureRecognizer(tapGesture)
        
        //Inserts the initial values into the database (only call this if row does not already exist).
        let persistentId = PersistentEntity.shared.insert(soundEffectsEnabled: true, musicEnabled: true, numberOfLives: 3, timeStopped: 0,
                                                          displayAds: true, highscoreArcade: 0, highscoreDemolition: 0, highestLevelAchieved: 1)
        
        if let persistentQuery: AnySequence<Row> = PersistentEntity.shared.queryAll() {
            for eachPersistent in persistentQuery {
                PersistentEntity.shared.toString(persistent: eachPersistent)
            }
        }
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
