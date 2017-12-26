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
    
    var currentLevelNum = 0
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
                self.scene.animateMatchedGems(for: chains) { //TODO do this same time as fire cannon animation? //TODO fix bug where this is called twice
                    let cannons = self.level.getCannons() //TODO refactor
                    self.scene.animateNewCannons(cannons: cannons) {
                        for chain in chains{
                            self.score += chain.score
                        }
                        self.updateLabels()
                        let columns = self.level.fillHoles() //TODO fix bug where this doesn't wait on cannon fire
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
    
    //TODO Recurse on cannon fire chain, create a new thread for each cannon that fires in the chain. Wait until all threads are finished before moving on
    func fireMatchedCannons(cannons: [Cannon], completion: @escaping () -> ()){
        if cannons.count == 0 {
            completion()
        }
        
        for i in (0..<cannons.count) {
            //TODO call these three methods inside another thread and repeat until no more hit cannons
            runCannonFireThreads(cannon: cannons[i]){}
        }
        
        group.notify(queue: queue) {
            completion()
        }
    }
    
    //TODO Replace these with threads
    func runCannonFireThreads(cannon: Cannon, completion: @escaping () -> ()){ //Takes a cannon tile and spins up one new thread for each cannon on that tile
        if cannon.cannonType == CannonType.twoWayHorz {
            queue.async(group: group) {self.fireCannon(cannon: cannon, direction: "East"){completion()}}
            queue.async(group: group) {self.fireCannon(cannon: cannon, direction: "West"){completion()}}
        }
        else if cannon.cannonType == CannonType.twoWayVert {
            queue.async(group: group) {self.fireCannon(cannon: cannon, direction: "North"){completion()}}
            queue.async(group: group) {self.fireCannon(cannon: cannon, direction: "South"){completion()}}
        }
        else {
            queue.async(group: group) {self.fireCannon(cannon: cannon, direction: "East"){completion()}}
            queue.async(group: group) {self.fireCannon(cannon: cannon, direction: "West"){completion()}}
            queue.async(group: group) {self.fireCannon(cannon: cannon, direction: "North"){completion()}}
            queue.async(group: group) {self.fireCannon(cannon: cannon, direction: "South"){completion()}}
        }
    }
    
    func fireCannon(cannon: Cannon, direction: String, completion: @escaping () -> ()) {
        let hitCannonTile = self.level.fireCannon(cannon: cannon, direction: direction) //need to call this two or four times with direction
        if(hitCannonTile == nil){
            //self.scene.animateRemoveCannon(cannon: cannon)
            completion()
            return
        }
        self.scene.animateHitCannon(cannon: hitCannonTile) {
            self.scene.animateRemoveCannon(cannon: hitCannonTile!)
            self.runCannonFireThreads(cannon: hitCannonTile!){
                 completion()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        backgroundMusic?.stop()
    }
}
