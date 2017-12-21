//
//  Wall.swift
//  SmashMatch
//
//  Created by Cameron Porter on 18/12/17.
//  Copyright © 2017 Cameron Porter. All rights reserved.
//

import SpriteKit

enum WallType: Int, CustomStringConvertible  {
    case unknown = 0, new, broken
    var spriteName: String {
        let spriteNames = [
            "brick",
            "brickcracked"]
        
        return spriteNames[rawValue - 1]
    }
    
    var highlightedSpriteName: String {
        return spriteName + "-Highlighted"
    }
    
    static func predefined(type: Int) -> GemType {
        return GemType(rawValue: type)!
    }
    
    var description: String {
        return spriteName
    }
}

class Wall: Gem {
    let wallType: WallType
    let horizontal: Bool
    
    init(column: Int, row: Int, wallType: WallType, horizontal: Bool) {
        self.wallType = wallType
        self.horizontal = horizontal
        super.init(column: column, row: row, gemType: GemType(rawValue: 6)!)
    }
    
    override var description: String {
        return "Wall square:(\(column),\(row))"
    }
    
    func generateWall(column: Int, row: Int) -> Wall? {
        if(arc4random_uniform(39) <= 1){
            return Wall(column: column, row: row, wallType: WallType.new, horizontal: horizontal)
        }
        return nil
    }
}

func ==(lhs: Wall, rhs: Wall) -> Bool {
    return lhs.column == rhs.column && lhs.row == rhs.row
}


