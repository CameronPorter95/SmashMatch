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
        let contentSize = CGSize(width: scrollView!.frame.width, height: scrollView!.frame.height * 4.73089) // makes it 4.73089 times the height, image height is 4.73089 * screen height
        scrollView?.contentSize = contentSize
        view.addSubview(scrollView)
        addChild(moveableNode)
        
        let backgroundImageSectionSize = CGSize(width: scrollView.frame.size.width, height:  scrollView.frame.size.height*1.182723) //4.73089/4
        let midY = frame.midY - (frame.height*0.0913615) //0.182723/2
        let backgroundImage1 = SKTexture(imageNamed: "LevelsBG1")
        let background1 = SKSpriteNode(texture: backgroundImage1, size: backgroundImageSectionSize)
        background1.position = CGPoint(x: frame.midX, y: midY)
        moveableNode.addChild(background1)
        
        let backgroundImage2 = SKTexture(imageNamed: "LevelsBG2")
        let background2 = SKSpriteNode(texture: backgroundImage2, size: backgroundImageSectionSize)
        background2.position = CGPoint(x: frame.midX, y: midY - (backgroundImageSectionSize.height))
        moveableNode.addChild(background2)
        
        let backgroundImage3 = SKTexture(imageNamed: "LevelsBG3")
        let background3 = SKSpriteNode(texture: backgroundImage3, size: backgroundImageSectionSize)
        background3.position = CGPoint(x: frame.midX, y: midY - (backgroundImageSectionSize.height * 2))
        moveableNode.addChild(background3)
        
        let backgroundImage4 = SKTexture(imageNamed: "LevelsBG4")
        let background4 = SKSpriteNode(texture: backgroundImage4, size: backgroundImageSectionSize)
        background4.position = CGPoint(x: frame.midX, y: midY - (backgroundImageSectionSize.height * 3))
        moveableNode.addChild(background4)
        
        //moveableNode.position.y = -contentSize.height
    }
    
    override func willMove(from view: SKView) {
        scrollView?.removeFromSuperview()
        scrollView = nil // nil out reference to deallocate properly
    }
    
    deinit {
        print("Deinit LevelSelection Scene")
    }
}
