//
//  MainMenu.swift
//  SmashMatch
//
//  Created by Cameron Porter on 29/12/17.
//  Copyright © 2017 Cameron Porter. All rights reserved.
//

import SpriteKit
import GameplayKit
import SQLite
import SQLite3

class MainMenu: SKScene {
    
    weak var heart1: SKSpriteNode?
    weak var heart2: SKSpriteNode?
    weak var heart3: SKSpriteNode?
    weak var heart4: SKSpriteNode?
    weak var heart5: SKSpriteNode?
    weak var plus: SKSpriteNode?
    weak var countDownLabel: SKLabelNode?
    
    var startTime = UInt64()
    var numer: UInt64 = 0
    var denom: UInt64 = 0
    var timer = Timer()
    var lives = 3;
    var score = 0
    
    override func didMove(to view: SKView) {
        heart1 = self.childNode(withName: "//Heart1") as? SKSpriteNode
        heart2 = self.childNode(withName: "//Heart2") as? SKSpriteNode
        heart3 = self.childNode(withName: "//Heart3") as? SKSpriteNode
        heart4 = self.childNode(withName: "//Heart4") as? SKSpriteNode
        heart5 = self.childNode(withName: "//Heart5") as? SKSpriteNode
        plus = self.childNode(withName: "//Plus") as? SKSpriteNode
        countDownLabel = self.childNode(withName: "//Countdown") as? SKLabelNode
        
        setupLifeTimer()
        addLife()
        runTimer()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch:UITouch = touches.first! as UITouch
        let positionInScene = touch.location(in: self)
        let touchedNode = self.atPoint(positionInScene)
        
        if let name = touchedNode.name {
            if name == "Arcade" {
                NotificationCenter.default.post(name: .arcadeButtonPressed, object: nil)
            }
        }
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
            _ = PersistentEntity.shared.updateAt(id: 1, index: 5, value: startTime as AnyObject)
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
            _ = PersistentEntity.shared.updateAt(id: 1, index: 5, value: startTime as AnyObject)
            _ = PersistentEntity.shared.updateAt(id: 1, index: 4, value: lives as AnyObject)
        }
    }

    func runTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(updateTimer)), userInfo: nil, repeats: true)
    }

    @objc func updateTimer(){
        if(lives < 5){
                let currTime = mach_absolute_time()
                let timeDiff = Double(((currTime - startTime) * numer) / denom)/1e9
            _ = PersistentEntity.shared.updateAt(id: 1, index: 5, value: currTime as AnyObject)
            let timeLeftForNextLife = 3600 - (timeDiff)

            //countDownLabel?.text = String(currTime)

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
                countDownLabel?.text = String("\(zeroM):\(zeroS)")
            }
            else if(zeroM != ""){
                countDownLabel?.text = String("\(zeroM):\(s)")
            }
            else if(zeroS != ""){
                countDownLabel?.text = String("\(m):\(zeroS)")
            }
            else{
                countDownLabel?.text = String("\(m):\(s)")
            }

            if(timeLeftForNextLife < 0){
                lives += 1
                addLife()
                startTime = currTime
            }
        }
    }

    func addLife(){
        if(lives > 0){
            heart1?.texture = SKTexture(imageNamed: "pinkheart")
            if(lives > 1){
                heart2?.texture = SKTexture(imageNamed: "pinkheart")
                if(lives > 2){
                    heart3?.texture = SKTexture(imageNamed: "pinkheart")
                    if(lives > 3){
                        heart4?.texture = SKTexture(imageNamed: "pinkheart")
                        if(lives > 4){
                            heart5?.texture = SKTexture(imageNamed: "pinkheart")
                        }
                    }
                }
            }
        }
    }

    func secondsToMinutesSeconds (seconds : Double) -> (Int, Int) {
        return (Int((seconds.truncatingRemainder(dividingBy:3600) / 60)), Int((seconds.truncatingRemainder(dividingBy:3600)).truncatingRemainder(dividingBy: 60)))
    }
}