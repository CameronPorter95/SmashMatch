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
    weak var settingsButton: SKSpriteNode?
    weak var westWall: SKSpriteNode?
    weak var settingsScroll: SKSpriteNode?
    weak var settingsExit: SKSpriteNode?
    weak var inAppScroll: SKSpriteNode?
    weak var addLifeButton: SKSpriteNode?
    
    var settingsScrollPhysics: SKPhysicsBody?
    var inAppScrollPhysics: SKPhysicsBody?
    var westWallPhysics: SKPhysicsBody?
    let noCategory:UInt32 = 0
    let westWallCategory:UInt32 = 0b1
    let settingsCategory:UInt32 = 0b1 << 1
    let inAppCategory:UInt32 = 0b1 << 2
    var collisionCount = 0
    
    var startTime = UInt64()
    var numer: UInt64 = 0
    var denom: UInt64 = 0
    var timer = Timer()
    var lives = 3;
    
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
        settingsButton = self.childNode(withName: "//Settings") as? SKSpriteNode
        westWall = self.childNode(withName: "WestWall") as? SKSpriteNode
        settingsScroll = self.childNode(withName: "SettingsScroll") as? SKSpriteNode
        settingsExit = self.childNode(withName: "//SettingsExit") as? SKSpriteNode
        settingsExit?.isHidden = true
        inAppScroll = self.childNode(withName: "PurchaseBanner") as? SKSpriteNode
        addLifeButton = self.childNode(withName: "LivesBackground") as? SKSpriteNode
        
        settingsScrollPhysics = SKPhysicsBody(rectangleOf: (settingsScroll?.size)!)
        settingsScrollPhysics?.isDynamic = true
        settingsScrollPhysics?.affectedByGravity = true
        settingsScrollPhysics?.allowsRotation = false
        settingsScrollPhysics?.mass = 4.0
        settingsScrollPhysics?.restitution = 0.2
        settingsScrollPhysics?.friction = 0.2
        settingsScrollPhysics?.categoryBitMask = settingsCategory
        settingsScrollPhysics?.collisionBitMask = westWallCategory
        settingsScrollPhysics?.contactTestBitMask = westWallCategory
        settingsScroll?.physicsBody = nil
        
        inAppScrollPhysics = SKPhysicsBody(rectangleOf: (inAppScroll?.size)!)
        inAppScrollPhysics?.isDynamic = true
        inAppScrollPhysics?.affectedByGravity = true
        inAppScrollPhysics?.allowsRotation = false
        inAppScrollPhysics?.mass = 4.0
        inAppScrollPhysics?.restitution = 0.2
        inAppScrollPhysics?.friction = 0.2
        inAppScrollPhysics?.categoryBitMask = inAppCategory
        inAppScrollPhysics?.collisionBitMask = westWallCategory
        inAppScrollPhysics?.contactTestBitMask = westWallCategory
        inAppScroll?.physicsBody = nil
        
        westWallPhysics = SKPhysicsBody(rectangleOf: (westWall?.size)!)
        westWallPhysics?.isDynamic = true
        westWallPhysics?.affectedByGravity = false
        westWallPhysics?.restitution = 0.0
        westWallPhysics?.categoryBitMask = westWallCategory
        westWallPhysics?.collisionBitMask = noCategory
        westWallPhysics?.contactTestBitMask = noCategory
        westWall?.physicsBody = nil
        
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
            } else if name == "Classic" {
                NotificationCenter.default.post(name: .classicButtonPressed, object: nil)
            } else if name == "Demolition" {
                NotificationCenter.default.post(name: .demolitionButtonPressed, object: nil)
            } else if name == "Settings" {
                if (settingsExit?.isHidden)! {
                    settingsScroll?.physicsBody = settingsScrollPhysics
                    westWall?.physicsBody = westWallPhysics
                    self.physicsWorld.gravity = CGVector(dx: -9.8, dy: 0)
                    let duration = TimeInterval(0.5)
                    let colorAction = SKAction.colorize(withColorBlendFactor: 0.4, duration: duration)
                    let fadeOutAction = SKAction.fadeOut(withDuration: duration)
                    background?.run(colorAction)
                    arcade?.run(fadeOutAction)
                    classic?.run(fadeOutAction)
                    demolition?.run(fadeOutAction)
                    DispatchQueue.global().async { self.disablePhysicsAfterBounce(sprite1: self.settingsScroll!, sprite2: self.westWall!) }
                    settingsExit?.isHidden = false
                    settingsButton?.isHidden = true
                    NotificationCenter.default.post(name: .settingsButtonPressed, object: nil)
                }
                
            } else if(name == "LivesBackground"){
                if (settingsExit?.isHidden)! {
                    inAppScroll?.physicsBody = inAppScrollPhysics
                    westWall?.physicsBody = westWallPhysics
                    self.physicsWorld.gravity = CGVector(dx: -9.8, dy: 0)
                    let duration = TimeInterval(0.5)
                    let colorAction = SKAction.colorize(withColorBlendFactor: 0.4, duration: duration)
                    let fadeOutAction = SKAction.fadeOut(withDuration: duration)
                    background?.run(colorAction)
                    arcade?.run(fadeOutAction)
                    classic?.run(fadeOutAction)
                    demolition?.run(fadeOutAction)
                    DispatchQueue.global().async { self.disablePhysicsAfterBounce(sprite1: self.inAppScroll!, sprite2: self.westWall!) }
                    settingsExit?.isHidden = false
                    settingsButton?.isHidden = true
                    NotificationCenter.default.post(name: .inAppButtonPressed, object: nil)
                }
                
                
                
            }else if name == "SettingsExit" {
                if collisionCount == -1 && (settingsButton?.isHidden)! {
                    settingsScroll?.physicsBody?.isDynamic = false
                    inAppScroll?.physicsBody?.isDynamic = false
                    self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
                    let duration = TimeInterval(0.5)
                    let moveActionSettings = SKAction.move(to: CGPoint(x: 322, y: -76) , duration: duration)
                    let moveActionInApp = SKAction.move(to: CGPoint(x: 322, y: 0) , duration: duration)
                    let colorAction = SKAction.colorize(withColorBlendFactor: 0.0, duration: duration)
                    let fadeInAction = SKAction.fadeIn(withDuration: duration)
                    settingsScroll?.run(moveActionSettings)
                    inAppScroll?.run(moveActionInApp)
                    background?.run(colorAction)
                    arcade?.run(fadeInAction)
                    classic?.run(fadeInAction)
                    demolition?.run(fadeInAction)
                    settingsExit?.isHidden = true
                    settingsButton?.isHidden = false
                    collisionCount = 0
                    NotificationCenter.default.post(name: .settingsExitButtonPressed, object: nil)
                }
            } else if name == "SFX" {
                
            } else if name == "Music" {
                
            } else if name == "HighScores" {
                
            } else if name == "AppPurchases" {
                
            } else if name == "Credits" {
                if collisionCount == -1 && (settingsButton?.isHidden)! {
                    NotificationCenter.default.post(name: .creditsButtonPressed, object: nil)
                }
            } else if name == "GameCenter" {
                
            } else if name == "Plus" {
                
            }
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let cA:UInt32 = contact.bodyA.categoryBitMask
        let cB:UInt32 = contact.bodyB.categoryBitMask
        
        if cA == settingsCategory || cB == settingsCategory {
            collisionCount += 1
        }
        else if cA == inAppCategory || cB == inAppCategory {
            collisionCount += 1
        }
    }
    
    func disablePhysicsAfterBounce(sprite1: SKSpriteNode, sprite2: SKSpriteNode){
        while true {
            if collisionCount > 2 {
                sprite1.physicsBody = nil
                sprite2.physicsBody = nil
                DispatchQueue.main.async {
                    self.collisionCount = -1
                }
                break
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
            
            let timeLeftForNextLife = 3600 - (timeDiff)

            let (m,s) = secondsToMinutesSeconds(seconds: timeLeftForNextLife)
            var zeroM = ""
            var zeroS = ""
            if(m < 10){
                zeroM = "0\(m)"
            }
            if(s < 10){
                zeroS = "0\(s)"
            }
            if(s < 0){
                zeroS = "00"
            }
            if(m < 0){
                zeroM = "00"
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
                _ = PersistentEntity.shared.updateAt(id: 1, index: 5, value: startTime as AnyObject)
                _ = PersistentEntity.shared.updateAt(id: 1, index: 4, value: lives as AnyObject)
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
    
    override func willMove(from view: SKView) {
        removeAllChildren()
        
    }
    
    deinit {
        print("Deinit MainMenu Scene")
    }
}
