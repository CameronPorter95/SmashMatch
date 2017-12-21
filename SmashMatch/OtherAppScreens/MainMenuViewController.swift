//
//  MainMenuViewController.swift
//  CookieCrunch
//
//  Created by Cameron Porter on 19/12/17.
//  Copyright © 2017 Cameron Porter. All rights reserved.
//

import UIKit
import GameKit
import SQLite
import SQLite3

class MainMenuViewController: UIViewController, GKGameCenterControllerDelegate {
    
    @IBOutlet weak var countDownLabel: UILabel!
    @IBOutlet weak var livesCounter: UIView!
    @IBAction func arcadeModePressed(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let gameViewController = storyboard.instantiateViewController(withIdentifier: "GameView")
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.rootViewController = gameViewController
    }
    @IBAction func demolitionModePressed(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let gameViewController = storyboard.instantiateViewController(withIdentifier: "GameView")
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.rootViewController = gameViewController
    }
    
    /* Variables */
    var gcEnabled = Bool() // Check if the user has Game Center enabled
    var gcDefaultLeaderBoard = String() // Check the default leaderboardID
    var startTime = UInt64()
    var numer: UInt64 = 0
    var denom: UInt64 = 0
    var timer = Timer()
    var lives = 3;
    var score = 0
    
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // IMPORTANT: replace the red string below with your own Leaderboard ID (the one you've set in iTunes Connect)
    let LEADERBOARD_ID = "com.score.smashmatch"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeDatabase()
        
        setupLifeTimer()
        addLife()

        // Call the GC authentication controller
        authenticateLocalPlayer()
         let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.touchedLives(sender:)))
        livesCounter.addGestureRecognizer(tapGesture)
        runTimer()
    }
    
    
    
    func setupLifeTimer(){
        var info = mach_timebase_info(numer: 0, denom: 0)
        mach_timebase_info(&info)
        numer = UInt64(info.numer)
        denom = UInt64(info.denom)
        
        
        if let persistentQuery: AnySequence<Row> = PersistentEntity.shared.queryFirst() {
            for eachPersistent in persistentQuery {
                startTime = PersistentEntity.shared.getKeyAt(persistent: eachPersistent, index: 5)! as! UInt64
                lives = PersistentEntity.shared.getKeyAt(persistent: eachPersistent, index: 4)! as! Int
            }
        }
        
        if(startTime == 0){
            startTime = mach_absolute_time()
            PersistentEntity.shared.updateAt(id: 1, index: 5, value: startTime as AnyObject)
            lives = 3
        }
        else{
            let currTime = mach_absolute_time()
            let timeDiff = Double(((currTime - startTime) * numer) / denom)/1e9
            
            lives = lives + Int(floor(timeDiff)/3600)
            if(lives > 5){
                lives = 5
            }
            startTime = currTime + UInt64(timeDiff.remainder(dividingBy: 3600))
            PersistentEntity.shared.updateAt(id: 1, index: 5, value: startTime as AnyObject)
            PersistentEntity.shared.updateAt(id: 1, index: 4, value: lives as AnyObject)
        }
        
        
        
    }
    
    func runTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(updateTimer)), userInfo: nil, repeats: true)
    }
    
    @objc func updateTimer(){
        if(lives < 5){
            let currTime = mach_absolute_time()
            let timeDiff = Double(((currTime - startTime) * numer) / denom)/1e9
        PersistentEntity.shared.updateAt(id: 1, index: 5, value: currTime as AnyObject)
        let timeLeftForNextLife = 3600 - (timeDiff)
        
        //countDownLabel.text = String(currTime)
            
        let (m,s) = secondsToMinutesSeconds(seconds: timeLeftForNextLife)
        var zeroM = ""
        var zeroS = ""
        if(m < 10){
            zeroM = "0\(m)"
        }
        if(s < 10){
            zeroS = "0\(s)"
        }
        if(zeroM != "" && zeroS != ""){
            countDownLabel.text = String("\(zeroM):\(zeroS)")
        }
        else if(zeroM != ""){
            countDownLabel.text = String("\(zeroM):\(s)")
        }
        else if(zeroS != ""){
            countDownLabel.text = String("\(m):\(zeroS)")
        }
        else{
            countDownLabel.text = String("\(m):\(s)")
        }

        if(timeLeftForNextLife < 0){
            lives += 1
            addLife()
            startTime = currTime
        }
        }
    }
    
    @IBOutlet weak var heart1: UIImageView!
    @IBOutlet weak var heart2: UIImageView!
    @IBOutlet weak var heart3: UIImageView!
    @IBOutlet weak var heart4: UIImageView!
    @IBOutlet weak var heart5: UIImageView!
    
    func addLife(){
        heart1.image = UIImage.init(named: "greyheart.png")
        heart2.image = UIImage.init(named: "greyheart.png")
        heart3.image = UIImage.init(named: "greyheart.png")
        heart4.image = UIImage.init(named: "greyheart.png")
        heart5.image = UIImage.init(named: "greyheart.png")
        
        if(lives > 0){
            heart1.image = UIImage.init(named: "heartbig.png")
            if(lives > 1){
                heart2.image = UIImage.init(named: "heartbig.png")
                if(lives > 2){
                    heart3.image = UIImage.init(named: "heartbig.png")
                    if(lives > 3){
                        heart4.image = UIImage.init(named: "heartbig.png")
                        if(lives > 4){
                            heart5.image = UIImage.init(named: "heartbig.png")
                        }
                    }
                }
            }
        }
        
        
    }
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
    
    @objc func touchedLives(sender: UITapGestureRecognizer) {
        print("touched the lives")
    }
    
    func secondsToMinutesSeconds (seconds : Double) -> (Int, Int) {
        return (Int((seconds.truncatingRemainder(dividingBy:3600) / 60)), Int((seconds.truncatingRemainder(dividingBy:3600)).truncatingRemainder(dividingBy: 60)))
    }
    
    func someAction(sender:UITapGestureRecognizer){
        // do other task
    }
    
    // or for Swift 3
    func someAction(_ sender:UITapGestureRecognizer){
        // do other task
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
