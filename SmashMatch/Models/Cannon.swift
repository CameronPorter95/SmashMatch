//
//  Cannon.swift
//  SmashMatch
//
//  Created by Cameron Porter on 18/12/17.
//  Copyright © 2017 Cameron Porter. All rights reserved.
//

import SpriteKit

enum CannonType: Int, CustomStringConvertible  {
    case unknown = 0, twoWayHorz, twoWayVert, fourWay
    var spriteName: String {
        let spriteNames = [
            "LRcannon",
            "UDcannon",
            "4cannon"]
        
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

class Cannon: Gem {
    let cannonType: CannonType
    
    init(column: Int, row: Int, cannonType: CannonType, gemType: GemType) {
        self.cannonType = cannonType
        super.init(column: column, row: row, gemType: gemType)
    }
    
    override var description: String {
        return "Cannon square:(\(column),\(row))"
    }
    
    override var spriteName: String {
        return gemType.spriteName + cannonType.spriteName
    }
}

func ==(lhs: Cannon, rhs: Cannon) -> Bool {
    return lhs.column == rhs.column && lhs.row == rhs.row
}

