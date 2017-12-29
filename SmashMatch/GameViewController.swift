//
//  GameViewController.swift
//  SmashMatch
//
//  Created by Cameron Porter on 29/12/17.
//  Copyright © 2017 Cameron Porter. All rights reserved.
//

import UIKit
import GameKit
import SpriteKit
import GameplayKit
import SQLite
import SQLite3

class GameViewController: UIViewController, GKGameCenterControllerDelegate {
    
    let gameController = GameController()
    var mainMenu: MainMenu?
    var levelSelection: LevelSelection?
    
    var gcEnabled = Bool() // Check if the user has Game Center enabled
    var gcDefaultLeaderBoard = String() // Check the default leaderboardID
    
    override var prefersStatusBarHidden: Bool {return true}
    override var shouldAutorotate: Bool {return true}
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait, .portraitUpsideDown]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeDatabase()
        NotificationCenter.default.addObserver(self, selector: #selector(self.showGameScene(_:)), name: Notification.Name.arcadeButtonPressed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.showLevelSelection(_:)), name: Notification.Name.classicButtonPressed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.showGameScene(_:)), name: Notification.Name.arcadeButtonPressed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.showMainMenu(_:)), name: Notification.Name.gameSceneBackButtonPressed, object: nil)
        
        // Call the GC authentication controller
        authenticateLocalPlayer()
        
        if let view = self.view as! SKView? {
            mainMenu = MainMenu(fileNamed: "MainMenu")
            mainMenu?.scaleMode = .fill
            view.presentScene(mainMenu)
        }
    }
    
    @objc func showGameScene(_ notification: Notification) {
        if let view = self.view as! SKView? {
            gameController.setupLevel(view: view)
        }
    }
    
    @objc func showLevelSelection(_ notification: Notification) {
        if let view = self.view as! SKView? {
            levelSelection = LevelSelection(fileNamed: "LevelSelection")
            levelSelection?.scaleMode = .aspectFill
            view.presentScene(levelSelection)
        }
    }
    
    @objc func showMainMenu(_ notification: Notification) {
        if let view = self.view as! SKView? {
            mainMenu = MainMenu(fileNamed: "MainMenu")
            mainMenu?.scaleMode = .aspectFill
            view.presentScene(mainMenu)
            gameController.backgroundMusic?.stop()
            gameController.backgroundMusic?.currentTime = 0
        }
    }
    
    // IMPORTANT: replace the red string below with your own Leaderboard ID (the one you've set in iTunes Connect)
    let LEADERBOARD_ID = "com.score.smashmatch"
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
    
    func authenticateLocalPlayer(){
        let localPlayer: GKLocalPlayer = GKLocalPlayer.localPlayer()
        
        localPlayer.authenticateHandler = {(ViewController, error) -> Void in
            if((ViewController) != nil) {
                // 1. Show login if player is not logged in
                self.present(ViewController!, animated: true, completion: nil)
            } else if (localPlayer.isAuthenticated) {
                // 2. Player is already authenticated & logged in, load game center
                self.gcEnabled = true
                
                // Get the default leaderboard ID
                localPlayer.loadDefaultLeaderboardIdentifier(completionHandler: { (leaderboardIdentifer, error) in
                    if error != nil { print(error as Any)
                    } else { self.gcDefaultLeaderBoard = leaderboardIdentifer! }
                })
                
            } else {
                // 3. Game center is not enabled on the users device
                self.gcEnabled = false
                print("Local player could not be authenticated!")
                print(error as Any)
            }
        }
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
        print("-----------------------DATABASE ROW AFTER LOAD-----------------------------")
        if let persistentQuery: AnySequence<Row> = PersistentEntity.shared.queryFirst() {
            for eachPersistent in persistentQuery {
                PersistentEntity.shared.toString(persistent: eachPersistent)
            }
        }
    }
    
    //    How to update and query all tables in database (for later).
    //
    //            if PersistentEntity.shared.update(id: 1,
    //                                              soundEffectsEnabled: true,
    //                                              musicEnabled: true,
    //                                              numberOfLives: 3,
    //                                              timeStopped: 0,
    //                                              displayAds: true,
    //                                              highscoreArcade: 0,
    //                                              highscoreDemolition: 0,
    //                                              highestLevelAchieved: 1) {
    //                print("Update successful")
    //            } else {
    //                print("Update unsuccessful")
    //            }
    //
    //            if let persistentQuery: AnySequence<Row> = PersistentEntity.shared.queryAll() {
    //                for eachPersistent in persistentQuery {
    //                    PersistentEntity.shared.toString(persistent: eachPersistent)
    //                }
    //            }
    
}
