//
//  MainMenuViewController.swift
//  CookieCrunch
//
//  Created by Cameron Porter on 19/12/17.
//  Copyright © 2017 Cameron Porter. All rights reserved.
//

import UIKit
import GameKit

class MainMenuViewController: UIViewController,
        GKGameCenterControllerDelegate
{
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var countDownLabel: UILabel!
    
    
        /* Variables */
        var gcEnabled = Bool() // Check if the user has Game Center enabled
        var gcDefaultLeaderBoard = String() // Check the default leaderboardID
    var startTime = 0;
    var timer = Timer()
        var score = 0
        
        // IMPORTANT: replace the red string below with your own Leaderboard ID (the one you've set in iTunes Connect)
        let LEADERBOARD_ID = "com.score.smashmatch"
    
    
    @IBOutlet weak var livesCounter: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startTime = Int(mach_absolute_time()/1000000000)
        // Call the GC authentication controller
        authenticateLocalPlayer()
         let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.touchedLives(sender:)))
        livesCounter.addGestureRecognizer(tapGesture)
        runTimer()
        
    }
    
    func runTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(updateTimer)), userInfo: nil, repeats: true)
    }
    
    @objc func updateTimer(){
        //Check the change in time from DB time to Curr time to see how many lifes the player gains
        let currTime = Int(mach_absolute_time()/1000000000)
        let timeLeftForNextLife = 3600 - (currTime - startTime)
        
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
        
        if(timeLeftForNextLife == 0){
            //remove a life
            //startTime = currTime
            
        }
        
        
    }
    
    @objc func touchedLives(sender: UITapGestureRecognizer) {
        print("touched the lives")

    }
    
    func secondsToMinutesSeconds (seconds : Int) -> (Int, Int) {
        return ((seconds % 3600) / 60, (seconds % 3600) % 60)
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
    
}
