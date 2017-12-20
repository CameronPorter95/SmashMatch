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
        initializeDatabase()
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
    
    func initializeDatabase(){
        //Look for existing data in database, if not found run the following insert statement.
        var tableHasValues = false
        if let persistentQuery: AnySequence<Row> = PersistentEntity.shared.queryFirst() {
            for eachPersistent in persistentQuery {
                if PersistentEntity.shared.hasRow(persistent: eachPersistent) {
                    tableHasValues = true
                }
            }
        }
        if(!tableHasValues){
            print("------------------INSERTING INITAL DATA INTO DATABASE------------------------------------")
            //Inserts the initial values into the database (only calls this if row does not already exist).
            _ = PersistentEntity.shared.insert(soundEffectsEnabled: true, musicEnabled: true, numberOfLives: 3, timeStopped: 0,
                                                              displayAds: true, highscoreArcade: 0, highscoreDemolition: 0, highestLevelAchieved: 1)
        }
        
        //Print the status of the persistent row, should have values at this point.
        print("-----------------------DATABASE ROW AFTER INITIAL INSERT-----------------------------")
        if let persistentQuery: AnySequence<Row> = PersistentEntity.shared.queryFirst() {
            for eachPersistent in persistentQuery {
                PersistentEntity.shared.toString(persistent: eachPersistent)
            }
        }
    }
    
    //How to update and query all tables in database (for later).
    
    //        if PersistentEntity.shared.update(id: 1,
    //                                          soundEffectsEnabled: true,
    //                                          musicEnabled: true,
    //                                          numberOfLives: 3,
    //                                          timeStopped: 0,
    //                                          displayAds: true,
    //                                          highscoreArcade: 0,
    //                                          highscoreDemolition: 0,
    //                                          highestLevelAchieved: 1) {
    //            print("Update successful")
    //        } else {
    //            print("Update unsuccessful")
    //        }
    //
    //        if let persistentQuery: AnySequence<Row> = PersistentEntity.shared.queryAll() {
    //            for eachPersistent in persistentQuery {
    //                PersistentEntity.shared.toString(persistent: eachPersistent)
    //            }
    //        }
}
