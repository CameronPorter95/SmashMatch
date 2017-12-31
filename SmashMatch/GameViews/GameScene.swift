//
//  GameScene.swift
//  SmashMatch
//
//  Created by Cameron Porter on 18/12/17.
//  Copyright © 2017 Cameron Porter. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder) is not used in this app")
    }
    
    private var swipeFromColumn: Int?
    private var swipeFromRow: Int?
    
    var swipeHandler: ((Swap) -> ())?
    var level: Level!
    var TileWidth: CGFloat = 32.0
    var TileHeight: CGFloat = 32.0
    var selectionSprite = SKSpriteNode()
    
    let gameLayer = SKNode()
    let tilesLayer = SKNode()
    let gemsLayer = SKNode()
    let wallsLayer = SKNode()
    
    var scoreLabelTitle: SKLabelNode!
    var timeLabelTitle: SKLabelNode!
    var scoreLabel: SKLabelNode!
    var timeLabel: SKLabelNode!
    weak var pauseScroll: SKSpriteNode?
    
    let noCategory:UInt32 = 0
    let southWallCategory:UInt32 = 0b1
    let pauseMenuCategory:UInt32 = 0b1 << 1
    
    let swapSound = SKAction.playSoundFileNamed("gem_swap.mp3", waitForCompletion: false)
    let invalidSwapSound = SKAction.playSoundFileNamed("Error.wav", waitForCompletion: false)
    let matchSound = SKAction.playSoundFileNamed("gem_match.mp3", waitForCompletion: false)
    let fallingGemSound = SKAction.playSoundFileNamed("Scrape.wav", waitForCompletion: false)
    let addGemSound = SKAction.playSoundFileNamed("Drip.wav", waitForCompletion: false)
    let specialMatchSound = SKAction.playSoundFileNamed("special_match.mp3", waitForCompletion: false)
    let cannonFireSound = SKAction.playSoundFileNamed("cannon.mp3", waitForCompletion: false)
    
    override init(size: CGSize) {
        super.init(size: size)
        self.physicsWorld.contactDelegate = self
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        
        TileWidth = size.width/10 + ((size.width/100)-(0.2666*(size.width/100)))
        TileHeight = TileWidth
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        let background = SKSpriteNode(imageNamed: "GameBackground")
        background.size = size
        addChild(background)
        let trees = SKSpriteNode(imageNamed: "Trees")
        trees.size = CGSize(width: size.width, height: size.width*0.32911)
        trees.anchorPoint = CGPoint(x: 0.5, y: 0)
        trees.position = CGPoint(x: 0, y: -size.height/2)
        addChild(trees)
        let bannerHeight = size.height/12
        let banner = SKSpriteNode(color: UIColor.white, size: CGSize(width: size.width, height: bannerHeight))
        banner.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        banner.position = CGPoint(x: 0.0, y: (size.height/2)-(bannerHeight*0.685))
        addChild(banner)
        let badge = SKSpriteNode(imageNamed: "Badge")
        badge.size = CGSize(width: size.width/3.8, height: size.width/3.8)
        badge.position = CGPoint(x: 0.0, y: 0.0-(size.height/20))
        banner.addChild(badge)
        let pause = SKSpriteNode(imageNamed: "Pause")
        pause.size = CGSize(width: bannerHeight*0.5, height: bannerHeight*0.5)
        pause.position = CGPoint(x: (size.width/2)*0.85, y: -bannerHeight*0.5)
        pause.name = "Pause"
        banner.addChild(pause)
        scoreLabelTitle = SKLabelNode(fontNamed: "System")
        scoreLabelTitle.text = "Score"
        scoreLabelTitle.fontColor = UIColor.black
        scoreLabelTitle.fontSize = 13
        scoreLabelTitle.position = CGPoint(x: (-size.width/3.2), y: -bannerHeight*0.40)
        banner.addChild(scoreLabelTitle)
        timeLabelTitle = SKLabelNode(fontNamed: "System")
        timeLabelTitle.text = "Time"
        timeLabelTitle.fontColor = UIColor.black
        timeLabelTitle.fontSize = 13
        timeLabelTitle.position = CGPoint(x: (size.width/3.9), y: -bannerHeight*0.40)
        banner.addChild(timeLabelTitle)
        scoreLabel = SKLabelNode(fontNamed: "Helvetica Neue")
        scoreLabel.text = "999999"
        scoreLabel.fontColor = UIColor.black
        scoreLabel.fontSize = 21
        scoreLabel.position = CGPoint(x: (-size.width/3.2), y: -bannerHeight*0.85)
        banner.addChild(scoreLabel)
        timeLabel = SKLabelNode(fontNamed: "Helvetica Neue")
        timeLabel.text = "2:00" //TODO Set initial based on level data
        timeLabel.fontColor = UIColor.black
        timeLabel.fontSize = 21
        timeLabel.position = CGPoint(x: (size.width/3.9), y: -bannerHeight*0.85)
        banner.addChild(timeLabel)
        
        let pauseScene:SKScene = SKScene(fileNamed: "PauseMenu")!
        pauseScroll = pauseScene.childNode(withName: "PauseScroll") as? SKSpriteNode
        pauseScroll?.position = CGPoint(x: 0, y: 503)
        pauseScroll?.move(toParent: self)
        let southWall = pauseScene.childNode(withName: "SouthWall")
        southWall?.position = CGPoint(x: 0, y: -244)
        southWall?.move(toParent: self)
        
        southWall?.physicsBody?.categoryBitMask = southWallCategory
        southWall?.physicsBody?.collisionBitMask = noCategory
        southWall?.physicsBody?.contactTestBitMask = noCategory
        
        pauseScroll?.physicsBody?.categoryBitMask = pauseMenuCategory
        pauseScroll?.physicsBody?.collisionBitMask = southWallCategory
        pauseScroll?.physicsBody?.contactTestBitMask = southWallCategory
        
        let back = SKSpriteNode(color: UIColor.black, size: CGSize(width: 20, height: 20))
        back.position = CGPoint(x: -50, y: ((size.height/2)-33)-77)
        back.name = "Back"
        addChild(back)
        
        let shuffle = SKSpriteNode(color: UIColor.red, size: CGSize(width: 20, height: 20))
        shuffle.position = CGPoint(x: +50, y: ((size.height/2)-33)-77)
        shuffle.name = "Shuffle"
        addChild(shuffle)
        
        addChild(gameLayer)
        
        let layerPosition = CGPoint(
            x: -TileWidth * CGFloat(NumColumns) / 2,
            y: -TileHeight * CGFloat(NumRows) / 2)
        
        tilesLayer.position = layerPosition
        gemsLayer.position = layerPosition
        wallsLayer.position = layerPosition
        gameLayer.addChild(tilesLayer)
        gameLayer.addChild(gemsLayer)
        gameLayer.addChild(wallsLayer)
        
        swipeFromColumn = nil
        swipeFromRow = nil
        let _ = SKLabelNode(fontNamed: "GillSans-BoldItalic")
    }
    
    func addTiles() {
        for row in 0..<NumRows {
            for column in 0..<NumColumns {
                if level.tileAt(column: column, row: row) != nil && column != 0 && column != NumColumns-1 && row != 0 && row != NumRows-1{
                    let tileNode = SKSpriteNode(imageNamed: "Tile")
                    tileNode.size = CGSize(width: TileWidth, height: TileHeight)
                    tileNode.position = pointFor(column: column, row: row)
                    tilesLayer.addChild(tileNode)
                }
            }
        }
    }
    
    func addSprites(for gems: Set<Gem>) {
        for gem in gems {
            var sprite: SKSpriteNode
            if(gem is Wall){
                let wall = gem as! Wall
                sprite = SKSpriteNode(imageNamed: wall.wallType.spriteName)
                wallsLayer.addChild(sprite)
                sprite.size = CGSize(width: TileWidth, height: TileWidth * 0.2666)
                var pos = pointFor(column: gem.column, row: gem.row)
                let offset = (TileWidth/2)-((0.2666*TileWidth)/2)
                if wall.horizontal == false {
                    sprite.zRotation = .pi/2
                    if(gem.column == 0){
                        pos.x = pos.x + offset
                    }
                    else {
                        pos.x = pos.x - offset
                    }
                } else {
                    if(gem.row == 0){
                        pos.y = pos.y + offset
                    }
                    else {
                        pos.y = pos.y - offset
                    }
                }
                sprite.position = pos
            } else {
                sprite = SKSpriteNode(imageNamed: gem.spriteName)
                gemsLayer.addChild(sprite)
                sprite.size = CGSize(width: TileWidth, height: TileHeight)
                sprite.position = pointFor(column: gem.column, row: gem.row)
            }
            gem.sprite = sprite
            // Give each gem sprite a small, random delay. Then fade them in.
            sprite.alpha = 0
            sprite.xScale = 0.5
            sprite.yScale = 0.5
            
            sprite.run(
                SKAction.sequence([
                    SKAction.wait(forDuration: 0.25, withRange: 0.5),
                    SKAction.group([
                        SKAction.fadeIn(withDuration: 0.25),
                        SKAction.scale(to: 1.0, duration: 0.25)
                        ])
                    ]))
        }
    }
    
    func removeAllGemSprites() {
        gemsLayer.removeAllChildren()
    }
    
    func showSelectionIndicator(gem: Gem) {
        if selectionSprite.parent != nil {
            selectionSprite.removeFromParent()
        }
        
        if let sprite = gem.sprite {
            let texture = SKTexture(imageNamed: gem.gemType.highlightedSpriteName)
            selectionSprite.size = CGSize(width: TileWidth, height: TileHeight)
            selectionSprite.run(SKAction.setTexture(texture))
            
            sprite.addChild(selectionSprite)
            selectionSprite.alpha = 1.0
        }
    }
    
    func hideSelectionIndicator() {
        selectionSprite.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()]))
    }
    
    func pointFor(column: Int, row: Int) -> CGPoint {
        return CGPoint(
            x: CGFloat(column)*TileWidth + TileWidth/2,
            y: CGFloat(row)*TileHeight + TileHeight/2)
    }
    
    func convertPoint(point: CGPoint) -> (success: Bool, column: Int, row: Int) {
        if point.x >= 0 && point.x < CGFloat(NumColumns)*TileWidth &&
            point.y >= 0 && point.y < CGFloat(NumRows)*TileHeight {
            return (true, Int(point.x / TileWidth), Int(point.y / TileHeight))
        } else {
            return (false, 0, 0)  // invalid location
        }
    }
    
    func trySwap(horizontal horzDelta: Int, vertical vertDelta: Int) {
        let toColumn = swipeFromColumn! + horzDelta
        let toRow = swipeFromRow! + vertDelta
        guard toColumn >= 0 && toColumn < NumColumns else { return }
        guard toRow >= 0 && toRow < NumRows else { return }
        if let toGem = level.gemAt(column: toColumn, row: toRow),
            let fromGem = level.gemAt(column: swipeFromColumn!, row: swipeFromRow!) {
            if let handler = swipeHandler {
                let swap = Swap(gemA: fromGem, gemB: toGem)
                handler(swap)
            }
        }
    }
    
    func animate(_ swap: Swap, completion: @escaping () -> ()) {
        let spriteA = swap.gemA.sprite!
        let spriteB = swap.gemB.sprite!
        
        spriteA.zPosition = 100
        spriteB.zPosition = 90
        
        let duration: TimeInterval = 0.3
        
        let moveA = SKAction.move(to: spriteB.position, duration: duration)
        moveA.timingMode = .easeOut
        spriteA.run(moveA, completion: completion)
        
        let moveB = SKAction.move(to: spriteA.position, duration: duration)
        moveB.timingMode = .easeOut
        spriteB.run(moveB)
        run(swapSound)
    }
    
    func animateInvalidSwap(_ swap: Swap, completion: @escaping () -> ()) {
        let spriteA = swap.gemA.sprite!
        let spriteB = swap.gemB.sprite!
        
        spriteA.zPosition = 100
        spriteB.zPosition = 90
        
        let duration: TimeInterval = 0.2
        
        let moveA = SKAction.move(to: spriteB.position, duration: duration)
        moveA.timingMode = .easeOut
        
        let moveB = SKAction.move(to: spriteA.position, duration: duration)
        moveB.timingMode = .easeOut
        
        spriteA.run(SKAction.sequence([moveA, moveB]), completion: completion)
        spriteB.run(SKAction.sequence([moveB, moveA]))
        run(invalidSwapSound)
    }
    
    func animateMatchedGems(for chains: Set<Chain>, completion: @escaping () -> ()) {
        for chain in chains {
            animateScore(for: chain)
            for gem in chain.gems {
                if let sprite = gem.sprite {
                    if sprite.action(forKey: "removing") == nil {
                        let scaleAction = SKAction.scale(to: 0.1, duration: 0.3)
                        scaleAction.timingMode = .easeOut
                        sprite.run(SKAction.sequence([scaleAction, SKAction.removeFromParent()]),
                                   withKey:"removing")
                    }
                }
            }
        }
        run(matchSound)
        run(SKAction.wait(forDuration: 0.3), completion: completion)
    }
    
    func animateFallingGems(columns: [[Gem]], completion: @escaping () -> ()) {
        var longestDuration: TimeInterval = 0
        for array in columns {
            for (idx, gem) in array.enumerated() {
                let newPosition = pointFor(column: gem.column, row: gem.row)
                let delay = 0.05 + 0.15*TimeInterval(idx)
                let sprite = gem.sprite!   // sprite always exists at this point
                let duration = TimeInterval(((sprite.position.y - newPosition.y) / TileHeight) * 0.1) //TODO use this logic for cannonball animation
                longestDuration = max(longestDuration, duration + delay)
                let moveAction = SKAction.move(to: newPosition, duration: duration)
                moveAction.timingMode = .easeOut
                sprite.run(
                    SKAction.sequence([
                        SKAction.wait(forDuration: delay),
                        SKAction.group([moveAction, fallingGemSound])]))
            }
        }
        run(SKAction.wait(forDuration: longestDuration), completion: completion)
    }
    
    func animateNewGems(_ columns: [[Gem]], completion: @escaping () -> ()) {
        var longestDuration: TimeInterval = 0
        
        for array in columns {
            let startRow = array[0].row + 1
            
            for (idx, gem) in array.enumerated() {
                let sprite = SKSpriteNode(imageNamed: gem.spriteName)
                sprite.size = CGSize(width: TileWidth, height: TileHeight)
                sprite.position = pointFor(column: gem.column, row: startRow)
                gemsLayer.addChild(sprite)
                gem.sprite = sprite
                let delay = 0.1 + 0.2 * TimeInterval(array.count - idx - 1)
                let duration = TimeInterval(startRow - gem.row) * 0.1
                longestDuration = max(longestDuration, duration + delay)
                let newPosition = pointFor(column: gem.column, row: gem.row)
                let moveAction = SKAction.move(to: newPosition, duration: duration)
                moveAction.timingMode = .easeOut
                sprite.alpha = 0
                sprite.run(
                    SKAction.sequence([
                        SKAction.wait(forDuration: delay),
                        SKAction.group([
                            SKAction.fadeIn(withDuration: 0.05),
                            moveAction,
                            addGemSound])
                        ]))
            }
        }
        run(SKAction.wait(forDuration: longestDuration), completion: completion)
    }
    
    //Animates the creation of cannons
    func animateNewCannons(cannons: Set<Cannon>, completion: @escaping () -> ()){
        for cannon in cannons {
            let sprite = SKSpriteNode(imageNamed: cannon.spriteName)
            sprite.size = CGSize(width: TileWidth, height: TileWidth)
            sprite.position = pointFor(column: cannon.column, row: cannon.row)
            gemsLayer.addChild(sprite)
            cannon.sprite = sprite
            // Give each gem sprite a small, random delay. Then fade them in.
            sprite.alpha = 0
            sprite.xScale = 0.5
            sprite.yScale = 0.5
            
            sprite.run(
                SKAction.sequence([
                    SKAction.group([
                        SKAction.fadeIn(withDuration: 0.25),
                        SKAction.scale(to: 1.0, duration: 0.25)
                        ])
                    ]))
        }
        run(SKAction.wait(forDuration: 0.25), completion: completion)
    }
    
    //Animates the creation of cannons
    func animateMatchedCannons(cannons: [Cannon], completion: @escaping () -> ()){
        if cannons.count == 0 {
            completion()
            return
        }
        run(cannonFireSound)
        for cannon in cannons {
            let f0, f1, f2, f3: SKTexture?
            if cannon.cannonType == CannonType.fourWay {
                f0 = SKTexture.init(imageNamed: "4cannon1")
                f1 = SKTexture.init(imageNamed: "4cannon2")
                f2 = SKTexture.init(imageNamed: "4cannon3")
                f3 = SKTexture.init(imageNamed: "4cannon4")
            } else if cannon.cannonType == CannonType.twoWayHorz {
                f0 = SKTexture.init(imageNamed: "LRcannon1")
                f1 = SKTexture.init(imageNamed: "LRcannon2")
                f2 = SKTexture.init(imageNamed: "LRcannon3")
                f3 = SKTexture.init(imageNamed: "LRcannon4")
            } else {
                f0 = SKTexture.init(imageNamed: "UDcannon1")
                f1 = SKTexture.init(imageNamed: "UDcannon2")
                f2 = SKTexture.init(imageNamed: "UDcannon3")
                f3 = SKTexture.init(imageNamed: "UDcannon4")
            }
            // Add frames
            let frames: [SKTexture] = [f0!, f1!, f2!, f3!]
            
            let sprite: SKSpriteNode?
            // Load the first frame as initialization
            if cannon.cannonType == CannonType.fourWay {
                sprite = SKSpriteNode(imageNamed: "\(cannon.gemType)4cannon")
            } else if cannon.cannonType == CannonType.twoWayHorz {
                sprite = SKSpriteNode(imageNamed: "\(cannon.gemType)LRcannon")
            } else {
                sprite = SKSpriteNode(imageNamed: "\(cannon.gemType)UDcannon")
            }
            
            sprite?.position = pointFor(column: cannon.column, row: cannon.row)
            sprite?.size = CGSize(width: TileWidth, height: TileWidth)
            gemsLayer.addChild(sprite!)
            // Change the frame per 0.2 sec
            let animation = SKAction.animate(with: frames, timePerFrame: 0.2)
            sprite?.run(animation)
        }
        run(SKAction.wait(forDuration: 0.8), completion: completion)
    }
    
    //Animates the creation of cannons
    func animateHitCannon(cannon: Cannon?, completion: @escaping () -> ()){
        if cannon == nil {
            completion()
            return
        }
        run(cannonFireSound)
        let f0, f1, f2, f3: SKTexture?
        if cannon?.cannonType == CannonType.fourWay {
            f0 = SKTexture.init(imageNamed: "4cannon1")
            f1 = SKTexture.init(imageNamed: "4cannon2")
            f2 = SKTexture.init(imageNamed: "4cannon3")
            f3 = SKTexture.init(imageNamed: "4cannon4")
        } else if cannon?.cannonType == CannonType.twoWayHorz {
            f0 = SKTexture.init(imageNamed: "LRcannon1")
            f1 = SKTexture.init(imageNamed: "LRcannon2")
            f2 = SKTexture.init(imageNamed: "LRcannon3")
            f3 = SKTexture.init(imageNamed: "LRcannon4")
        } else {
            f0 = SKTexture.init(imageNamed: "UDcannon1")
            f1 = SKTexture.init(imageNamed: "UDcannon2")
            f2 = SKTexture.init(imageNamed: "UDcannon3")
            f3 = SKTexture.init(imageNamed: "UDcannon4")
        }
        // Add frames
        let frames: [SKTexture] = [f0!, f1!, f2!, f3!]
        
        let sprite: SKSpriteNode?
        // Load the first frame as initialization
        if cannon?.cannonType == CannonType.fourWay {
            sprite = SKSpriteNode(imageNamed: "\(cannon!.gemType)4cannon")
        } else if cannon?.cannonType == CannonType.twoWayHorz {
            sprite = SKSpriteNode(imageNamed: "\(cannon!.gemType)LRcannon")
        } else {
            sprite = SKSpriteNode(imageNamed: "\(cannon!.gemType)UDcannon")
        }
        
        sprite?.position = pointFor(column: (cannon?.column)!, row: (cannon?.row)!)
        sprite?.size = CGSize(width: TileWidth, height: TileWidth)
        gemsLayer.addChild(sprite!)
        // Change the frame per 0.2 sec
        let animation = SKAction.animate(with: frames, timePerFrame: 0.2)
        sprite?.run(animation)
        run(SKAction.wait(forDuration: 0.8), completion: completion)
    }
    
    func animateRemoveCannon(cannon: Cannon){
        if let sprite = cannon.sprite {
            if sprite.action(forKey: "removing") == nil {
                let scaleAction = SKAction.scale(to: 0.1, duration: 0.3)
                scaleAction.timingMode = .easeOut
                sprite.run(SKAction.sequence([scaleAction, SKAction.removeFromParent()]),
                           withKey:"removing")
            }
        }
        run(SKAction.wait(forDuration: 0.3))
    }
    
    func animateScore(for chain: Chain) { //TODO Move label position to intercept gem for intercept chains
        let firstSprite = chain.firstGem().sprite!
        let lastSprite = chain.lastGem().sprite!
        let centerPosition = CGPoint(
            x: (firstSprite.position.x + lastSprite.position.x)/2,
            y: (firstSprite.position.y + lastSprite.position.y)/2 - 10)
        
        let scoreLabel = SKLabelNode(fontNamed: "GillSans-BoldItalic")
        scoreLabel.fontSize = 16
        scoreLabel.text = String(format: "%ld", chain.score)
        scoreLabel.position = centerPosition
        scoreLabel.zPosition = 300
        gemsLayer.addChild(scoreLabel)
        
        let moveAction = SKAction.move(by: CGVector(dx: 0, dy: 3), duration: 0.7)
        moveAction.timingMode = .easeOut
        scoreLabel.run(SKAction.sequence([moveAction, SKAction.removeFromParent()]))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: gemsLayer)
        let (success, column, row) = convertPoint(point: location)
        if success {
            if let gem = level.gemAt(column: column, row: row) {
                //showSelectionIndicator(gem: gem)
                swipeFromColumn = column
                swipeFromRow = row
                return
            }
        } else {
            let positionInScene = touch.location(in: self)
            let touchedNode = self.atPoint(positionInScene)
            
            if let name = touchedNode.name {
                if name == "Back" {
                    removeAllGemSprites()
                    NotificationCenter.default.post(name: .gameSceneBackButtonPressed, object: nil)
                } else if name == "Shuffle" {
                    NotificationCenter.default.post(name: .shuffleButtonPressed, object: nil)
                } else if name == "Pause" {
                    print("Responding to pause press")
                    pauseScroll?.physicsBody?.isDynamic = true
                    self.physicsWorld.gravity = CGVector(dx: 0, dy: -13)
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard swipeFromColumn != nil else { return }
        guard let touch = touches.first else { return }
        let location = touch.location(in: gemsLayer)
        
        let (success, column, row) = convertPoint(point: location)
        if success {
            var horzDelta = 0, vertDelta = 0
            if column < swipeFromColumn! {          // swipe left
                horzDelta = -1
            } else if column > swipeFromColumn! {   // swipe right
                horzDelta = 1
            } else if row < swipeFromRow! {         // swipe down
                vertDelta = -1
            } else if row > swipeFromRow! {         // swipe up
                vertDelta = 1
            }
            if horzDelta != 0 || vertDelta != 0 {
                trySwap(horizontal: horzDelta, vertical: vertDelta)
                //hideSelectionIndicator()
                swipeFromColumn = nil
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if selectionSprite.parent != nil && swipeFromColumn != nil {
            //hideSelectionIndicator()
        }
        swipeFromColumn = nil
        swipeFromRow = nil
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
}
