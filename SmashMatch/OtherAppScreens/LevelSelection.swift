//
//  LevelSelection.swift
//  SmashMatch
//
//  Created by Cameron Porter on 29/12/17.
//  Copyright © 2017 Cameron Porter. All rights reserved.
//

import SpriteKit
import SwiftySKScrollView

class LevelSelection: SKScene {
    
    var scrollView: SwiftySKScrollView!
    let moveableNode = SKNode()
    
    override func didMove(to view: SKView) {
        scrollView = SwiftySKScrollView(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height), moveableNode: moveableNode, direction: .vertical)
        let contentSize = CGSize(width: scrollView!.frame.width, height: scrollView!.frame.height * 15) // makes it 3 times the height
        scrollView?.contentSize = contentSize
        view.addSubview(scrollView)
        addChild(moveableNode)
        
        let backgroundImage = SKTexture(imageNamed: "levelsBG") //TODO Split into multiple images
        let background = SKSpriteNode(texture: backgroundImage, size: contentSize)
        background.position = CGPoint(x: 0, y: -contentSize.height/2)
        moveableNode.addChild(background)
    }
    
    override func willMove(from view: SKView) {
        scrollView?.removeFromSuperview()
        scrollView = nil // nil out reference to deallocate properly
    }
}
