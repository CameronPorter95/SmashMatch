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

class MainMenu: SKScene, SKPhysicsContactDelegate {
    
    weak var background: SKSpriteNode?
    weak var arcade: SKSpriteNode?
    weak var classic: SKSpriteNode?
    weak var demolition: SKSpriteNode?
    weak var heart1: SKSpriteNode?
    weak var heart2: SKSpriteNode?
    weak var heart3: SKSpriteNode?
    weak var heart4: SKSpriteNode?
    weak var heart5: SKSpriteNode?
    weak var plus: SKSpriteNode?
    weak var countDownLabel: SKLabelNode?
    weak var settings: SKSpriteNode?
    weak var westWall: SKSpriteNode?
    weak var settingsScroll: SKSpriteNode?
    weak var settingsExit: SKSpriteNode?
    
    let noCategory:UInt32 = 0
    let westWallCategory:UInt32 = 0b1
    let settingsCategory:UInt32 = 0b1 << 1
    
    var startTime = UInt64()
    var numer: UInt64 = 0
    var denom: UInt64 = 0
    var timer = Timer()
    var lives = 3;
    var score = 0 //Why is this here?
    
    override func didMove(to view: SKView) {
        self.physicsWorld.contactDelegate = self
        
        background = self.childNode(withName: "Background") as? SKSpriteNode
        arcade = self.childNode(withName: "//Arcade") as? SKSpriteNode
        classic = self.childNode(withName: "//Classic") as? SKSpriteNode
        demolition = self.childNode(withName: "//Demolition") as? SKSpriteNode
        heart1 = self.childNode(withName: "//Heart1") as? SKSpriteNode
        heart2 = self.childNode(withName: "//Heart2") as? SKSpriteNode
        heart3 = self.childNode(withName: "//Heart3") as? SKSpriteNode
        heart4 = self.childNode(withName: "//Heart4") as? SKSpriteNode
        heart5 = self.childNode(withName: "//Heart5") as? SKSpriteNode
        plus = self.childNode(withName: "//Plus") as? SKSpriteNode
        countDownLabel = self.childNode(withName: "//Countdown") as? SKLabelNode
        settings = self.childNode(withName: "//Settings") as? SKSpriteNode
        westWall = self.childNode(withName: "WestWall") as? SKSpriteNode
        settingsScroll = self.childNode(withName: "SettingsScroll") as? SKSpriteNode
        settingsExit = self.childNode(withName: "//SettingsExit") as? SKSpriteNode
        settingsExit?.isHidden = true
        
        westWall?.physicsBody?.categoryBitMask = westWallCategory
        westWall?.physicsBody?.collisionBitMask = noCategory
        westWall?.physicsBody?.contactTestBitMask = noCategory
        
        settingsScroll?.physicsBody?.categoryBitMask = settingsCategory
        settingsScroll?.physicsBody?.collisionBitMask = westWallCategory
        settingsScroll?.physicsBody?.contactTestBitMask = westWallCategory
        
        setupLifeTimer()
        addLife()
        runTimer()
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let cA:UInt32 = contact.bodyA.categoryBitMask
        let cB:UInt32 = contact.bodyB.categoryBitMask
        
        if cA == settingsCategory || cB == settingsCategory {
            print("Responding to scroll collision")
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch:UITouch = touches.first! as UITouch
        let positionInScene = touch.location(in: self)
        let touchedNode = self.atPoint(positionInScene)
        
        if let name = touchedNode.name {
            if name == "Arcade" {
                NotificationCenter.default.post(name: .arcadeButtonPressed, object: nil)
            } else if name == "Classic" {
                NotificationCenter.default.post(name: .classicButtonPressed, object: nil)
            } else if name == "Demolition" {
                NotificationCenter.default.post(name: .demolitionButtonPressed, object: nil)
            } else if name == "Settings" {
                settingsScroll?.physicsBody?.isDynamic = true
                self.physicsWorld.gravity = CGVector(dx: -9.8, dy: 0)
                let duration = TimeInterval(0.5)
                let colorAction = SKAction.colorize(withColorBlendFactor: 0.4, duration: duration)
                let fadeOutAction = SKAction.fadeOut(withDuration: duration)
                background?.run(colorAction)
                arcade?.run(fadeOutAction)
                classic?.run(fadeOutAction)
                demolition?.run(fadeOutAction)
                settingsExit?.isHidden = false
                settings?.isHidden = true
            } else if name == "SettingsExit" {
                settingsScroll?.physicsBody?.isDynamic = false
                self.physicsWorld.gravity = CGVector(dx: 0, dy: 0) //TODO Why does scroll go back when canceling part way through motion?
                let duration = TimeInterval(0.5)
                let moveAction = SKAction.move(to: CGPoint(x: 322, y: -76) , duration: duration)
                let colorAction = SKAction.colorize(withColorBlendFactor: 0.0, duration: duration)
                let fadeInAction = SKAction.fadeIn(withDuration: duration)
                settingsScroll?.run(moveAction)
                background?.run(colorAction)
                arcade?.run(fadeInAction)
                classic?.run(fadeInAction)
                demolition?.run(fadeInAction)
                settingsExit?.isHidden = true
                settings?.isHidden = false
            }
        }
    }
    
    func disableInteractionForDuration(duration: TimeInterval, completion: @escaping () -> ()){
        isUserInteractionEnabled = false
        run(SKAction.wait(forDuration: duration), completion: completion)
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

    @objc func updateTimer(){ //TODO rewrite this to use a DateComponentsFormatter
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
