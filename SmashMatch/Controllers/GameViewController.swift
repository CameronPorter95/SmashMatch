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

class GameViewController: UIViewController {
    var scene: GameScene!
    var level: Level!
    
    var currentLevelNum = 1
    var movesMade = 0
    var score = 0
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
    
    @IBOutlet weak var scoreLabel: UILabel!
    @IBAction func shuffleBoard(_ sender: Any) {
        shuffle()
    }
    
    @IBAction func backPressed(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let mainMenuViewController = storyboard.instantiateViewController(withIdentifier: "MainMenu")
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.rootViewController = mainMenuViewController
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait, .portraitUpsideDown]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLevel(levelNum: currentLevelNum)
        backgroundMusic?.play()
        //TODO increase current level upon level completion and call setupLevel again to go to next level
    }
    
    func setupLevel(levelNum: Int) {
        let skView = view as! SKView
        skView.isMultipleTouchEnabled = false
        scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .aspectFill
        level = Level(filename: "Level_\(levelNum)")
        scene.level = level
        
        scene.addTiles()
        scene.swipeHandler = handleSwipe
        
        skView.presentScene(scene)
        beginGame()
    }
    
    func beginGame() {
        movesMade = 0
        score = 0
        updateLabels()
        shuffle()
    }
    
    func beginNextTurn() {
        if(level.detectPossibleSwaps().capacity == 0) {
            shuffle()
        }
        view.isUserInteractionEnabled = true
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
        view.isUserInteractionEnabled = false
        
        if level.isPossibleSwap(swap) {
            level.performSwap(swap: swap)
            scene.animate(swap, completion: handleMatches)
        } else {
            scene.animateInvalidSwap(swap) {
                self.view.isUserInteractionEnabled = true
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
        self.scene.animateMatchedCannons(cannons: matchedCannons){
            self.fireMatchedCannons(cannons: matchedCannons){
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
    }
    
    func updateLabels() {
        scoreLabel.text = String(format: "%ld", score)
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
            runCannonFireThreads(cannon: cannons[i])
        }
        group.notify(queue: queue) {
            completion()
        }
    }
    
    /**
     Takes a cannon tile and spins up one new thread for each cannon on that tile
     */
    func runCannonFireThreads(cannon: Cannon){
        if cannon.cannonType == CannonType.twoWayHorz {
            group.enter();self.fireCannon(cannon: cannon, direction: "East"){}
            group.enter();self.fireCannon(cannon: cannon, direction: "West"){}
        }
        else if cannon.cannonType == CannonType.twoWayVert {
            group.enter();self.fireCannon(cannon: cannon, direction: "North"){}
            group.enter();self.fireCannon(cannon: cannon, direction: "South"){}
        }
        else {
            group.enter();self.fireCannon(cannon: cannon, direction: "East"){}
            group.enter();self.fireCannon(cannon: cannon, direction: "West"){}
            group.enter();self.fireCannon(cannon: cannon, direction: "North"){}
            group.enter();self.fireCannon(cannon: cannon, direction: "South"){}
        }
    }
    
    func fireCannon(cannon: Cannon, direction: String, completion: @escaping () -> ()) {
        let hitCannonTile = self.level.fireCannon(cannon: cannon, direction: direction)
        if(hitCannonTile == nil){
            //self.scene.animateRemoveCannon(cannon: cannon)
            self.group.leave()
            completion()
            return
        }
        self.scene.animateHitCannon(cannon: hitCannonTile) {
            //self.queue.async(group: self.group) {self.scene.animateRemoveCannon(cannon: hitCannonTile!)}
            self.scene.animateRemoveCannon(cannon: hitCannonTile!)
            self.runCannonFireThreads(cannon: hitCannonTile!)
            self.group.leave()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        backgroundMusic?.stop()
    }
}
