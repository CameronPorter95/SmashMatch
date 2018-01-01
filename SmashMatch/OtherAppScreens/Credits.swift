//
//  Credits.swift
//  SmashMatch
//
//  Created by Cameron Porter on 1/01/18.
//  Copyright © 2018 Cameron Porter. All rights reserved.
//

import SpriteKit

class Credits: SKScene {

    override func didMove(to view: SKView) {
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch:UITouch = touches.first! as UITouch
        let positionInScene = touch.location(in: self)
        let touchedNode = self.atPoint(positionInScene)
        
        if let name = touchedNode.name {
            if name == "Exit" {
                NotificationCenter.default.post(name: .backToMainMenu, object: nil)
            }
        }
    }
}
