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
    
    var currentLevelNum = 1 //TODO increase current level upon level completion and call setupLevel again to go to next level
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
        self.fireMatchedCannons(cannons: matchedCannons){ //TODO mysterious cannon not falling all the way bug (only on top of other cannons?)
            self.scene.animateMatchedGems(for: chains) { //TODO do this same time as fire cannon animation?
                let cannons = self.level.getCannons() //TODO refactor
                self.scene.animateNewCannons(cannons: cannons) {
                    for chain in chains{
                        self.score += chain.score
                    }
                    self.updateLabels()
                    let columns = self.level.fillHoles()
                    self.scene.animateFallingGems(columns: columns) {
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
        for i in (0..<cannons.count) {
            createCannonFireTasks(cannon: cannons[i])
        }
        group.notify(queue: queue) {
            completion()
        }
    }
    
    /**
     Takes a cannon tile and adds a new task to the dispatch queue for each cannon on the tile
     */
    func createCannonFireTasks(cannon: Cannon){
        if cannon.cannonType == CannonType.twoWayHorz {
            group.enter();queue.async{ self.fireCannon(cannon: cannon, direction: "East"){} }
            group.enter();queue.async{ self.fireCannon(cannon: cannon, direction: "West"){} }
        }
        else if cannon.cannonType == CannonType.twoWayVert {
            group.enter();queue.async{ self.fireCannon(cannon: cannon, direction: "North"){} }
            group.enter();queue.async{ self.fireCannon(cannon: cannon, direction: "South"){} }
        }
        else {
            group.enter();queue.async{ self.fireCannon(cannon: cannon, direction: "East"){} }
            group.enter();queue.async{ self.fireCannon(cannon: cannon, direction: "West"){} }
            group.enter();queue.async{ self.fireCannon(cannon: cannon, direction: "North"){} }
            group.enter();queue.async{ self.fireCannon(cannon: cannon, direction: "South"){} }
        }
    }
    
    func fireCannon(cannon: Cannon, direction: String, completion: @escaping () -> ()) {
        let hitTiles = self.level.fireCannon(cannon: cannon, direction: direction)
//        if(hitTile?.gemType == GemType.unknown){ //make hitCannonTile never nil but either a wall or empty tile if no cannon
//
//        }
        
        for tile in hitTiles! {
            group.enter()
            var distance: Int
            if direction == "East" || direction == "West"{
                distance = (tile.column) - cannon.column
            } else {
                distance = (tile.row) - cannon.row
            }
            let from = CGPoint(x: cannon.column, y: cannon.row)
            let to =  CGPoint(x: (tile.column), y: (tile.row))
            let duration: Double = abs(Double(distance)/10.0)
            self.scene.animateCannonball(from: from, to: to, duration: duration, direction: direction){
                //print("completed animation to: \(to)")
                if tile is Cannon {
                    self.scene.animateHitCannon(cannon: tile as? Cannon){
                        self.scene.animateRemoveCannon(cannon: tile as! Cannon)
                    }
                    self.createCannonFireTasks(cannon: tile as! Cannon)
                } else if tile is Wall {
                    let wall = tile as! Wall
                    self.scene.animateBreakWall(wall: wall)
                } else {
                    //self.scene.animateRemoveCannon(cannon: cannon)
                    self.group.leave()
                    completion()
                    return
                }
               self.group.leave()
            }
        }
        self.group.leave()
    }
    
    @objc func shuffleNotification(_ notification: Notification) {
        shuffle()
    }
}
