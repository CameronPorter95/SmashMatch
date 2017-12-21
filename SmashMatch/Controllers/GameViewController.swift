//
//  GameViewController.swift
//  CookieCrunch
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
    
    lazy var backgroundMusic: AVAudioPlayer? = {
        guard let url = Bundle.main.url(forResource: "Mining by Moonlight", withExtension: "mp3") else {
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
    
    @IBOutlet weak var targetLabel: UILabel!
    @IBOutlet weak var movesLabel: UILabel!
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
        scene.removeAllCookieSprites()
        let newCookies = level.shuffle()
        scene.addSprites(for: newCookies)
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
        scene.animateMatchedCookies(for: chains) {
            let cannons = self.level.getCannons()
            self.scene.animateNewCannons(cannons: cannons) {
                let columns = self.level.fillHoles()
                self.scene.animateFallingCookies(columns: columns) {
                    let columns = self.level.topUpCookies()
                    self.scene.animateNewCookies(columns) {
                        self.handleMatches()
                    }
                }
            }
        }
    }
    
    func updateLabels() {
        targetLabel.text = String(format: "%ld", level.targetScore)
        movesLabel.text = String(format: "%ld", movesMade)
        scoreLabel.text = String(format: "%ld", score)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        backgroundMusic?.stop()
    }
}
