//
//  GameViewController.swift
//  SmashMatch
//
//  The controller for the actual smash match game.
//
//  Smash Match uses a strict MVC pattern, this (the controller) handles data transfer and
//  method calls between the model (Level.swift) and the view (GameScene.swift).
//
//  The controller holds the central game loop and also initialises the game.
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
    
    /**
     * Setup the model for storing and manipulation of data and present the view for displaying
     * said information
     **/
    func setupLevel(view: SKView, mode: String) {
        self.view = view
        view.isMultipleTouchEnabled = false
        scene = GameScene(size: (view.bounds.size))
        scene.scaleMode = .aspectFill
        if mode != "Classic" {currentLevelNum = 0}
        else {
            
        }
        level = Level(filename:  "Level_\(currentLevelNum)", mode: mode)
        scene.level = level
        scene.addTiles()
        scene.swipeHandler = handleSwipe
        
        view.presentScene(scene)
        backgroundMusic?.play()
        timeLeft = 120 //TODO read from database
        beginGame()
    }
    
    /**
     * Shuffle the game board and initialise game values
     **/
    func beginGame() {
        movesMade = 0
        score = 0
        updateLabels()
        level.resetComboMultiplier()
        shuffle()
    }
    
    /**
     * Reset the combo multiplier and shuffle the game board if no possible moves
     **/
    func beginNextTurn() {
        level.resetComboMultiplier()
        if(level.detectPossibleSwaps().capacity == 0) {
            shuffle()
        }
        view?.isUserInteractionEnabled = true
        incrementMoves();
    }
    
    /**
     * Clear the game board and add all new gems.
     **/
    func shuffle() {
        scene.removeAllGemSprites()
        let newGems = level.shuffle()
        scene.addSprites(for: newGems)
    }
    
    func incrementMoves() {
        movesMade += 1
        updateLabels()
        if level.getWalls().isEmpty {
            if level.isClassicMode {
                self.scene.animateHazarScroll()
            } else if level.isDemolitionMode {
                self.scene.animateHazarScroll()
            }
        }
    }
    
    /**
     * Called each time the user makes a swipe, checks if the swap will make a match
     * and if so animate a success, other animate a failure.
     **/
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
    
    /**
     * The central game loop which is called each time a match is made,
     * performs each step after waiting the previous to finish and recurses
     * if another match is made in the process.
     **/
    func handleMatches() {
        let chains = level.removeMatches()
        if chains.count == 0 {
            beginNextTurn() //If no more matches are made then return.
            return
        }
        let matchedCannons = getCannonsFromChains(chains: chains)
        self.scene.animateMatchedCannons(cannons: matchedCannons)
        self.fireMatchedCannons(cannons: matchedCannons){
            self.scene.animateMatchedGems(for: chains) {
                let cannons = self.level.getCannons() //TODO refactor
                self.scene.animateNewCannons(cannons: cannons) {
                    for chain in chains {
                        self.score += chain.score
                    }
                    self.updateLabels()
                    let columns = self.level.fillHoles() //Make existing gems on top of matches fall to fill the empty space.
                    self.scene.animateFallingGems(columns: columns) {
                        let columns = self.level.topUpGems() //Creates new gems to fill the empty spaces created by making matches.
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
        if(scene != nil && !scene.isGamePaused){
            if(timeLeft >= 0) {
                let formatter = DateComponentsFormatter()
                formatter.allowedUnits = [.minute, .second]
                formatter.zeroFormattingBehavior = .pad
                formatter.unitsStyle = .positional
                let formattedString = formatter.string(from: TimeInterval(timeLeft))!
                scene.timeLabel.text = formattedString
                timeLeft -= 1
            } else {
                if level.isClassicMode {
                    self.scene.animateOhNoScroll()
                } else if level.isArcadeMode {
                    self.scene.animateHazarScroll()
                }
            }
        }
    }
    
    func getCannonsFromChains(chains: Set<Chain>) -> [Cannon]{
        var cannons = [Cannon]()
        for chain in chains {
            for gem in chain.gems {
                if gem is Cannon {
                    let cannon = gem as! Cannon
                    cannons.append(gem as! Cannon)
                    if cannon.cannonType == .fourWay {score += 400}
                    else {score += 200}
                }
            }
        }
        return cannons
    }
    
    /**
     * Sets up the cannon fire tasks and waits until they have all finished firing.
     */
    func fireMatchedCannons(cannons: [Cannon], completion: @escaping () -> ()){
        for i in (0..<cannons.count) {
            createCannonFireTasks(cannon: cannons[i])
        }
        group.notify(queue: queue) {
            completion()    //Only move on to the next stage in the game loop after all cannons have finished firing.
        }
    }
    
    /**
     * Takes a cannon tile and adds a new task to the dispatch group for each cannon on the tile
     */
    func createCannonFireTasks(cannon: Cannon){
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
    }
    
    /**
     * calculates the result of the firing of the cannonball and animates it.
     */
    func fireCannon(cannon: Cannon, direction: String) {
        let hitTiles = self.level.fireCannon(cannon: cannon, direction: direction)
        
        let tile = hitTiles?.last
        let from = CGPoint(x: cannon.column, y: cannon.row)
        let duration = calculateDuration(direction: direction, cannon: cannon, hitTile: tile!)
        group.enter()
        self.scene.animateCannonball(from: from, to: tile!, duration: duration, direction: direction){self.group.leave()}
        for tile in hitTiles! {
            let duration = calculateDuration(direction: direction, cannon: cannon, hitTile: tile)
            self.group.enter()
            self.scene.waitFor(duration: duration){
                self.respondToHit(cannon: cannon, hitTile: tile, direction: direction)
            }        }
        self.group.leave()
    }
    
    /**
     * If a wall is hit, break/destroy it. If a cannon is hit, recurse on createCannonFireTasks()
     * to create a chain reaction.
     */
    func respondToHit(cannon: Cannon, hitTile: Gem, direction: String){
        if hitTile is Cannon {
            let hitCannon = hitTile as! Cannon
            self.scene.animateHitCannon(cannon: hitCannon){
                self.scene.animateRemoveCannon(cannon: hitCannon)
                if hitCannon.cannonType == .fourWay {
                    self.score += 400
                    self.scene.animateScore(for: hitCannon, chainScore: 0)
                } else {
                    self.score += 200
                }
            }
            self.createCannonFireTasks(cannon: hitTile as! Cannon)
        } else if hitTile is Wall {
            let wall = hitTile as! Wall
            self.scene.animateHitWall(wall: wall) //do this once
        } else {
            self.group.leave()
            return
        }
        self.group.leave()
    }
    
    /**
     * Get the distance a cannonball has to travel in order to hit the given tile.
     * Used for calculating the animation time.
     */
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
