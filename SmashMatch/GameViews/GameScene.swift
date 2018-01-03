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
    
    var background: SKSpriteNode!
    var trees: SKSpriteNode!
    var pause: SKSpriteNode!
    var scoreLabelTitle: SKLabelNode!
    var timeLabelTitle: SKLabelNode!
    var scoreLabel: SKLabelNode!
    var timeLabel: SKLabelNode!
    var pauseScroll: SKSpriteNode!
    var southWall: SKSpriteNode!
    
    var pauseScrollPhysics: SKPhysicsBody?
    var southWallPhysics: SKPhysicsBody?
    let noCategory:UInt32 = 0
    let southWallCategory:UInt32 = 0b1
    let pauseMenuCategory:UInt32 = 0b1 << 1
    var collisionCount = 0
    
    let swapSound = SKAction.playSoundFileNamed("gem_swap.mp3", waitForCompletion: false)
    let invalidSwapSound = SKAction.playSoundFileNamed("Error.wav", waitForCompletion: false)
    let matchSound = SKAction.playSoundFileNamed("gem_match.mp3", waitForCompletion: false)
    let fallingGemSound = SKAction.playSoundFileNamed("Scrape.wav", waitForCompletion: false)
    let addGemSound = SKAction.playSoundFileNamed("Drip.wav", waitForCompletion: false)
    let specialMatchSound = SKAction.playSoundFileNamed("special_match.mp3", waitForCompletion: false)
    let cannonFireSound = SKAction.playSoundFileNamed("cannon.mp3", waitForCompletion: false)
    let wallCrackSound = SKAction.playSoundFileNamed("wall_crack.mp3", waitForCompletion: false)
    let wallSmashSound = SKAction.playSoundFileNamed("wall_smash.mp3", waitForCompletion: false)
    
    var isGamePaused = false
    
    override init(size: CGSize) {
        super.init(size: size)
        self.physicsWorld.contactDelegate = self
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        
        TileWidth = size.width/10 + ((size.width/100)-(0.2666*(size.width/100)))
        TileHeight = TileWidth
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        background = SKSpriteNode(imageNamed: "GameBackground")
        background.size = size
        addChild(background)
        trees = SKSpriteNode(imageNamed: "Trees")
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
        pause = SKSpriteNode(imageNamed: "Pause")
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
        
        let scrollWidth = size.width
        let scrollHeight = scrollWidth*1.328
        pauseScroll = SKSpriteNode(imageNamed: "longbanner")
        orientSprite(sprite: pauseScroll!, size: CGSize(width: scrollWidth, height: scrollHeight), position: CGPoint(x: 0, y: (size.height/2)+scrollHeight))
        pauseScroll.zPosition = 1000
        addChild(pauseScroll!)
        let resume = SKSpriteNode(imageNamed: "resume")
        orientSprite(sprite: resume, size: CGSize(width: scrollWidth*0.65625, height: scrollHeight*0.11059), position: CGPoint(x: 0, y: scrollHeight*0.20705))
        resume.name = "Resume"
        pauseScroll?.addChild(resume)
        let quit = SKSpriteNode(imageNamed: "quit")
        orientSprite(sprite: quit, size: CGSize(width: scrollWidth*0.65625, height: scrollHeight*0.11059), position: CGPoint(x: 0, y: scrollHeight*0.05411))
        quit.name = "Quit"
        pauseScroll?.addChild(quit)
        let sfx = SKSpriteNode(imageNamed: "sound")
        orientSprite(sprite: sfx, size: CGSize(width: scrollWidth*0.19687, height: scrollWidth*0.19687), position: CGPoint(x: -scrollWidth*0.23438, y: -scrollHeight*0.14353))
        sfx.name = "SFX"
        pauseScroll?.addChild(sfx)
        let music = SKSpriteNode(imageNamed: "music")
        orientSprite(sprite: music, size: CGSize(width: scrollWidth*0.19687, height: scrollWidth*0.19687), position: CGPoint(x: 0, y: -scrollHeight*0.14353))
        music.name = "Music"
        pauseScroll?.addChild(music)
        let restart = SKSpriteNode(imageNamed: "restart")
        orientSprite(sprite: restart, size: CGSize(width: scrollWidth*0.212, height: scrollWidth*0.19687), position: CGPoint(x: scrollWidth*0.23438, y: -scrollHeight*0.14353))
        restart.name = "Restart"
        pauseScroll?.addChild(restart)
        let heartSize = CGSize(width: scrollWidth*0.125, height: scrollHeight*0.07059)
        let greyHeart1 = SKSpriteNode(imageNamed: "greybig")
        orientSprite(sprite: greyHeart1, size: heartSize, position: CGPoint(x: -scrollWidth*0.29062, y: scrollHeight*0.35764))
        pauseScroll?.addChild(greyHeart1)
        let greyHeart2 = SKSpriteNode(imageNamed: "greybig")
        orientSprite(sprite: greyHeart2, size: heartSize, position: CGPoint(x: -scrollWidth*0.14531, y: scrollHeight*0.35764))
        pauseScroll?.addChild(greyHeart2)
        let greyHeart3 = SKSpriteNode(imageNamed: "greybig")
        orientSprite(sprite: greyHeart3, size: heartSize, position: CGPoint(x: 0, y: scrollHeight*0.35764))
        pauseScroll?.addChild(greyHeart3)
        let greyHeart4 = SKSpriteNode(imageNamed: "greybig")
        orientSprite(sprite: greyHeart4, size: heartSize, position: CGPoint(x: scrollWidth*0.14531, y: scrollHeight*0.35764))
        pauseScroll?.addChild(greyHeart4)
        let greyHeart5 = SKSpriteNode(imageNamed: "greybig")
        orientSprite(sprite: greyHeart5, size: heartSize, position: CGPoint(x: scrollWidth*0.29062, y: scrollHeight*0.35764))
        pauseScroll?.addChild(greyHeart5)
        southWall = SKSpriteNode(color: .black, size: CGSize(width: 320, height: 5))
        southWall.position = CGPoint(x: 0, y: -(size.height/2)*0.86)
        southWall.alpha = 0.0
        addChild(southWall)
        
        pauseScrollPhysics = SKPhysicsBody(rectangleOf: pauseScroll.size)
        pauseScrollPhysics?.isDynamic = true
        pauseScrollPhysics?.affectedByGravity = true
        pauseScrollPhysics?.allowsRotation = false
        pauseScrollPhysics?.mass = 1.0
        pauseScrollPhysics?.restitution = 0.0
        pauseScrollPhysics?.friction = 0.0
        pauseScrollPhysics?.categoryBitMask = pauseMenuCategory
        pauseScrollPhysics?.collisionBitMask = southWallCategory
        pauseScrollPhysics?.contactTestBitMask = southWallCategory
        
        southWallPhysics = SKPhysicsBody(rectangleOf: southWall.size)
        southWallPhysics?.isDynamic = true
        southWallPhysics?.affectedByGravity = false
        southWallPhysics?.restitution = 0.0
        southWallPhysics?.categoryBitMask = southWallCategory
        southWallPhysics?.collisionBitMask = noCategory
        southWallPhysics?.contactTestBitMask = noCategory
        
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
            //print("DEBUG before animateScore")
            animateScore(for: chain)
            //print("DEBUG after animateScore")
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
    
    func animateMatchedCannons(cannons: [Cannon]){
        if cannons.count == 0 {
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
            let frames: [SKTexture] = [f0!, f1!, f2!, f3!]
            let sprite: SKSpriteNode?
            
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
            
            let animation = SKAction.animate(with: frames, timePerFrame: 0.2)
            sprite?.run(animation){
                sprite?.removeFromParent()
            }
        }
        run(SKAction.wait(forDuration: 0.8)) //TODO change duration depending on how far cannonball travels
    }
    
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
        sprite?.run(animation){
            sprite?.removeFromParent()
        }
        run(SKAction.wait(forDuration: 0.8), completion: completion)
    }
    
    func animateCannonball(from: CGPoint, to: Gem, duration: Double, direction: String, completion: @escaping () -> ()){
        //print("Firing cannon to: \(to), duration: \(duration)")
        let sprite = SKSpriteNode(imageNamed: "cannonball")
        var endTo = CGPoint(x: to.column, y: to.row)
        
        let fadeOutLength: CGFloat = 2.0
        switch direction {
        case "North":
            sprite.zRotation = .pi/2
            endTo.y += fadeOutLength
        case "South":
            sprite.zRotation = (.pi/2)*3
            endTo.y -= fadeOutLength
        case "East":
            endTo.x += fadeOutLength
        case "West":
            endTo.x -= fadeOutLength
            sprite.zRotation = .pi
        default:
            break
        }
        sprite.position = pointFor(column: Int(from.x), row: Int(from.y))
        sprite.size = CGSize(width: TileWidth/2, height: TileWidth/4) //TODO setup correct dimensions
        gemsLayer.addChild(sprite)
        let beginFadeOutPos = pointFor(column: to.column, row: to.row)
        let endFadeOutPos = pointFor(column: Int(endTo.x), row: Int(endTo.y))
        
        let moveAction1 = SKAction.move(to: beginFadeOutPos, duration: duration)
        let moveAction2 = SKAction.move(to: endFadeOutPos, duration: TimeInterval(fadeOutLength/10))
        let fadeOutAction = SKAction.fadeOut(withDuration: TimeInterval(fadeOutLength/10))
        sprite.run(moveAction1){
            if to is Wall == false {
                sprite.run(SKAction.sequence([SKAction.group([
                    moveAction2, fadeOutAction])
                    ])){
                        sprite.removeFromParent()
                        completion()
                }
            } else {
                sprite.removeFromParent()
                completion()
            }
        }
        //run(SKAction.wait(forDuration: duration), completion: completion)
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
    
    func animateHitWall(wall: Wall){
//        if wall == nil {
//            return
//        }
        
//        let f0 = SKTexture.init(imageNamed: "")                               TODO Setup wall breaking sprites here (cannonball impact)
//        let f1 = SKTexture.init(imageNamed: "")
//        let f2 = SKTexture.init(imageNamed: "")
//        let f3 = SKTexture.init(imageNamed: "")
//
//        let frames: [SKTexture] = [f0!, f1!, f2!, f3!]
//        let sprite = SKSpriteNode(imageNamed: "")
        
//        sprite.position = pointFor(column: wall.column, row: wall.row)
//        sprite.size = CGSize(width: TileWidth, height: TileWidth)             TODO orient impact sprites correctly
//        gemsLayer.addChild(sprite!)
        
//        let animation = SKAction.animate(with: frames, timePerFrame: 0.2)
//        sprite?.run(animation)
        if wall.wallType == .broken && wall.isDestroyed == false {
            print("Breaking wall")
            run(wallCrackSound)
            wall.sprite?.texture = SKTexture(imageNamed: "brickcracked")
        } else {
            print("Smashing wall")
            run(wallSmashSound)
            wall.sprite?.removeFromParent()
        }
    }
    
    func animateScore(for chain: Chain) { //TODO Move label position to intercept gem for intercept chains
        //print("DEBUG before getting sprites")
        let firstSprite = chain.firstGem().sprite!
        let lastSprite = chain.lastGem().sprite!
        //print("DEBUG before getting position")
        let centerPosition = CGPoint(
            x: (firstSprite.position.x + lastSprite.position.x)/2,
            y: (firstSprite.position.y + lastSprite.position.y)/2 - 10)
        
        let scoreLabel = SKLabelNode(fontNamed: "GillSans-BoldItalic")
        scoreLabel.fontSize = 16
        scoreLabel.text = String(format: "%ld", chain.score)
        scoreLabel.position = centerPosition
        scoreLabel.zPosition = 300
        //print("DEBUG before adding score to layer")
        gemsLayer.addChild(scoreLabel)
        //print("DEBUG after adding score to layer")
        let moveAction = SKAction.move(by: CGVector(dx: 0, dy: 3), duration: 0.7)
        moveAction.timingMode = .easeOut
        //print("DEBUG before run score animation")
        scoreLabel.run(SKAction.sequence([moveAction, SKAction.removeFromParent()]))
        //print("DEBUG after run score animation")
    }
    
    func waitFor(duration: Double, completion: @escaping () -> ()){
        run(SKAction.wait(forDuration: duration), completion: completion)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: gemsLayer)
        let (success, column, row) = convertPoint(point: location)
        if success && !isGamePaused {
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
                    NotificationCenter.default.post(name: .backToMainMenu, object: nil)
                } else if name == "Shuffle" {
                    NotificationCenter.default.post(name: .shuffleButtonPressed, object: nil)
                } else if name == "Pause" { //TODO disable physics after scroll has fallen in place
                    if !isGamePaused {
                        pauseScroll.physicsBody = pauseScrollPhysics
                        southWall.physicsBody = southWallPhysics
                        self.physicsWorld.gravity = CGVector(dx: 0, dy: -20)
                        pause.texture = SKTexture(imageNamed: "pausered")
                        let duration = TimeInterval(0.5)
                        let colorAction = SKAction.colorize(withColorBlendFactor: 0.4, duration: duration)
                        let fadeOutAction = SKAction.fadeOut(withDuration: duration)
                        background?.run(colorAction)
                        trees.run(fadeOutAction)
                        gameLayer.run(fadeOutAction)
                        isGamePaused = true
                        DispatchQueue.global().async { self.disablePhysicsAfterBounce(sprite1: self.pauseScroll, sprite2: self.southWall) }
                    }
                } else if name == "Resume" {
                    if collisionCount == -1 && isGamePaused { //Can only resume if pauseScroll has finished transition
                        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
                        pause.texture = SKTexture(imageNamed: "Pause")
                        let duration = TimeInterval(0.5)
                        let scrollPositionY = ((self.view?.frame.size.height)!/2)+(self.view?.frame.size.width)!*1.328
                        let moveAction = SKAction.move(to: CGPoint(x: 0, y: scrollPositionY) , duration: duration)
                        let colorAction = SKAction.colorize(withColorBlendFactor: 0.0, duration: duration)
                        let fadeInAction = SKAction.fadeIn(withDuration: duration)
                        background?.run(colorAction)
                        trees.run(fadeInAction)
                        gameLayer.run(fadeInAction)
                        pauseScroll?.run(moveAction)
                        isGamePaused = false
                        collisionCount = 0
                    }
                } else if name == "Quit" {
                    removeAllGemSprites()
                    NotificationCenter.default.post(name: .backToMainMenu, object: nil)
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
    
    func orientSprite(sprite: SKSpriteNode, size: CGSize, position: CGPoint){
        sprite.size = size
        sprite.position = position
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let cA:UInt32 = contact.bodyA.categoryBitMask
        let cB:UInt32 = contact.bodyB.categoryBitMask
        
        if cA == pauseMenuCategory || cB == pauseMenuCategory {
            collisionCount += 1
        }
    }
    
    func disablePhysicsAfterBounce(sprite1: SKSpriteNode, sprite2: SKSpriteNode){
        while true {
            if collisionCount > 1 {
                sprite1.physicsBody = nil
                sprite2.physicsBody = nil
                DispatchQueue.main.async {
                    self.collisionCount = -1
                }
                break
            }
        }
    }
    
    override func willMove(from view: SKView) {
        removeAllChildren()
    }
    
    deinit {
        print("Deinit Game Scene")
    }
}
