//
//  Gem.swift
//  SmashMatch
//
//  Created by Cameron Porter on 18/12/17.
//  Copyright © 2017 Cameron Porter. All rights reserved.
//

import SpriteKit

enum GemType: Int, CustomStringConvertible  {
    case unknown = 0, blue, green, orange, pink, yellow, wall, cannon
    var spriteName: String {
        let spriteNames = [
            "blue",
            "green",
            "orange",
            "pink",
            "yellow",
            "Wall",
            "Cannon"]
        
        return spriteNames[rawValue - 1]
    }
    
    var highlightedSpriteName: String {
        return spriteName + "-Highlighted"
    }
    
    static func random() -> GemType {
        return GemType(rawValue: Int(arc4random_uniform(5)) + 1)!
    }
    
    static func predefined(type: Int) -> GemType {
        return GemType(rawValue: type)!
    }
    
    var description: String {
        return spriteName
    }
}

class Gem: CustomStringConvertible, Hashable {
    var column: Int
    var row: Int
    let gemType: GemType
    var sprite: SKSpriteNode?
    var moved: Bool = false; //Used for flaging possible gems that could have caused chains (potential future cannons).
    
    init(column: Int, row: Int, gemType: GemType) {
        self.column = column
        self.row = row
        self.gemType = gemType
    }
    
    var hashValue: Int {
        return row*10 + column
    }
    
    var description: String {
        return "type:\(gemType) square:(\(column),\(row))"
    }
    
    var spriteName: String {
        return gemType.spriteName + "gem"
    }
}

func ==(lhs: Gem, rhs: Gem) -> Bool {
    return lhs.column == rhs.column && lhs.row == rhs.row
}
