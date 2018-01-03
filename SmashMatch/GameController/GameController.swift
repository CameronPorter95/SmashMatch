//
//  GameViewController.swift
//  SmashMatch
//
//  Created by Cameron Porter on 18/12/17.
//  Copyright © 2017 Cameron Porter. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit
import AVFoundation

class GameController {
    weak var view: SKView?
    var scene: GameScene!
    var level: Level!
    
    var currentLevelNum = 3 //TODO increase current level upon level completion and call setupLevel again to go to next level
    var movesMade = 0
    var score = 0
    var timeLeft = Int()
    let queue = DispatchQueue(label: "com.siso.smashmatch.cannonqueue", attributes: .concurrent)
    let group = DispatchGroup()
    
    lazy var backgroundMusic: AVAudioPlayer? = {
        guard let url = Bundle.main.url(forResource: "iOS Game Theme Medieval Version", withExtension: "wav") else {
            return nil
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            return player
        } catch {
            return nil
        }
    }()
    
    init(){
        NotificationCenter.default.addObserver(self, selector: #selector(self.shuffleNotification(_:)), name: Notification.Name.shuffleButtonPressed, object: nil)
        
        var _ = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
    }
    
    func setupLevel(view: SKView) {
        self.view = view
        view.isMultipleTouchEnabled = false
        scene = GameScene(size: (view.bounds.size))
        scene.scaleMode = .aspectFill
        level = Level(filename: "Level_\(currentLevelNum)")
        scene.level = level
        
        scene.addTiles()
        scene.swipeHandler = handleSwipe
        
        view.presentScene(scene)
        backgroundMusic?.play()
        timeLeft = 120
        beginGame()
    }
    
    func beginGame() {
        movesMade = 0
        score = 0
        updateLabels()
        level.resetComboMultiplier()
        shuffle()
    }
    
    func beginNextTurn() {
        level.resetComboMultiplier()
        if(level.detectPossibleSwaps().capacity == 0) {
            shuffle()
        }
        view?.isUserInteractionEnabled = true
        incrementMoves();
    }
    
    func shuffle() {
        scene.removeAllGemSprites()
        let newGems = level.shuffle()
        scene.addSprites(for: newGems)
    }
    
    func incrementMoves() {
        movesMade += 1
        updateLabels()
    }
    
    func handleSwipe(_ swap: Swap) {
        view?.isUserInteractionEnabled = false
        
        if level.isPossibleSwap(swap) {
            level.performSwap(swap: swap)
            scene.animate(swap, completion: handleMatches)
        } else {
            scene.animateInvalidSwap(swap) {
                self.view?.isUserInteractionEnabled = true
            }
        }
    }
    
    func handleMatches() {
        let chains = level.removeMatches()
        if chains.count == 0 {
            beginNextTurn()
            return
        }
        let matchedCannons = getCannonsFromChains(chains: chains)
        self.scene.animateMatchedCannons(cannons: matchedCannons)
        self.fireMatchedCannons(cannons: matchedCannons){
            //print("DEBUG before animateMatchedGems")
            self.scene.animateMatchedGems(for: chains) {
                //print("DEBUG before level.getCannons")
                let cannons = self.level.getCannons() //TODO refactor
                //print("DEBUG before animateNewCannons")
                self.scene.animateNewCannons(cannons: cannons) {
                    for chain in chains{
                        self.score += chain.score
                    }
                    self.updateLabels()
                    //print("DEBUG before fillHoles")
                    let columns = self.level.fillHoles()
                    self.scene.animateFallingGems(columns: columns) {
                        //print("DEBUG before topUpGems")
                        let columns = self.level.topUpGems()
                        self.scene.animateNewGems(columns) {
                            self.handleMatches()
                        }
                    }
                }
            }
        }
    }
    
    func updateLabels() {
        scene.scoreLabel.text = String(format: "%ld", score)
    }
    
    @objc func updateTimer() {
        if(scene != nil){
            if(timeLeft >= 0) {
                let formatter = DateComponentsFormatter()
                formatter.allowedUnits = [.minute, .second]
                formatter.zeroFormattingBehavior = .pad
                formatter.unitsStyle = .positional
                let formattedString = formatter.string(from: TimeInterval(timeLeft))!
                scene.timeLabel.text = formattedString
                timeLeft -= 1
            }
        }
    }
    
    func getCannonsFromChains(chains: Set<Chain>) -> [Cannon]{
        var cannons = [Cannon]()
        for chain in chains {
            for gem in chain.gems {
                if gem is Cannon {
                    cannons.append(gem as! Cannon)
                }
            }
        }
        return cannons
    }
    
    func fireMatchedCannons(cannons: [Cannon], completion: @escaping () -> ()){
        //print("DEBUG start of fireMatchedCannons")
        for i in (0..<cannons.count) {
            createCannonFireTasks(cannon: cannons[i])
        }
        group.notify(queue: queue) {
            //print("DEBUG end of fireMatchedCannons")
            print("-------------------------------------------------------------")
            completion()
        }
    }
    
    /**
     Takes a cannon tile and adds a new task to the dispatch queue for each cannon on the tile
     */
    func createCannonFireTasks(cannon: Cannon){
        //print("DEBUG start of createCannonFireTasks")
        if cannon.cannonType == CannonType.twoWayHorz {
            group.enter();self.fireCannon(cannon: cannon, direction: "East")
            group.enter();self.fireCannon(cannon: cannon, direction: "West")
        }
        else if cannon.cannonType == CannonType.twoWayVert {
            group.enter();self.fireCannon(cannon: cannon, direction: "North")
            group.enter();self.fireCannon(cannon: cannon, direction: "South")
        }
        else {
            group.enter();self.fireCannon(cannon: cannon, direction: "East")
            group.enter();self.fireCannon(cannon: cannon, direction: "West")
            group.enter();self.fireCannon(cannon: cannon, direction: "North")
            group.enter();self.fireCannon(cannon: cannon, direction: "South")
        }
        //print("DEBUG end of createCannonFireTasks")
    }
    
    func fireCannon(cannon: Cannon, direction: String) {
        //print("DEBUG start of controller.fireCannon")
        let hitTiles = self.level.fireCannon(cannon: cannon, direction: direction)
//        if(hitTile?.gemType == GemType.unknown){ //make hitCannonTile never nil but either a wall or empty tile if no cannon
//
//        }
        
        let tile = hitTiles?.last
        let from = CGPoint(x: cannon.column, y: cannon.row)
        //let to =  CGPoint(x: (tile!.column), y: (tile!.row))
        let duration = calculateDuration(direction: direction, cannon: cannon, hitTile: tile!)
        self.scene.animateCannonball(from: from, to: tile!, duration: duration, direction: direction) //TODO, find a way to wait for animation to finish but not finish; and not break everything at the same time...
        for tile in hitTiles! {
            let duration = calculateDuration(direction: direction, cannon: cannon, hitTile: tile)
            self.group.enter()
            self.scene.waitFor(duration: duration){
                self.respondToHit(cannon: cannon, hitTile: tile, direction: direction)
            }
            //print("DEBUG Start of iterating over hitTiles")
        }
        //print("DEBUG end of animateCannonball completion")
        self.group.leave()
    }
    
    func respondToHit(cannon: Cannon, hitTile: Gem, direction: String){
        //print("DEBUG start of respondToHit")
        //print("completed animation to: \(to)")
        if hitTile is Cannon {
            self.scene.animateHitCannon(cannon: hitTile as? Cannon){
                //print("DEBUG finished animateHitCannon")
                self.scene.animateRemoveCannon(cannon: hitTile as! Cannon)
            }
            //print("DEBUG before CreateCannonFireTasks")
            self.createCannonFireTasks(cannon: hitTile as! Cannon)
            //print("DEBUG after CreateCannonFireTasks")
        } else if hitTile is Wall {
            let wall = hitTile as! Wall
            //print("DEBUG animateHitWall")
            self.scene.animateHitWall(wall: wall) //do this once
        } else {
            //print("DEBUG group end when hit empty tile")
            //self.scene.animateRemoveCannon(cannon: cannon)
            self.group.leave()
            //completion()
            return
        }
        //completion()
        //print("DEBUG group end at end of respondHit")
        self.group.leave()
    }
    
    func calculateDuration(direction: String, cannon: Cannon, hitTile: Gem) -> Double {
        var distance: Int
        if direction == "East" || direction == "West"{
            distance = abs((hitTile.column) - cannon.column)
        } else {
            distance = abs((hitTile.row) - cannon.row)
        }
        return Double(distance)/10.0
    }
    
    @objc func shuffleNotification(_ notification: Notification) {
        shuffle()
    }
}
