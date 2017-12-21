//
//  Cookie.swift
//  CookieCrunch
//
//  Created by Cameron Porter on 18/12/17.
//  Copyright © 2017 Cameron Porter. All rights reserved.
//

import SpriteKit

enum CannonType: Int, CustomStringConvertible  {
    case unknown = 0, twoWayHorz, twoWayVert, fourWay
    var spriteName: String {
//        let spriteNames = [
//            "blueLRcannon",
//            "blueUDcannon",
//            "blue4cannon",
//            "greenLRcannon",
//            "greenUDcannon",
//            "green4cannon",
//            "orangeLRcannon",
//            "orangeUDcannon",
//            "orange4cannon",
//            "pinkLRcannon",
//            "pinkUDcannon",
//            "pink4cannon",
//            "yellowLRcannon",
//            "yellowUDcannon",
//            "yellow4cannon"]
        
        let spriteNames = [
            "LRcannon",
            "UDcannon",
            "4cannon"]
        
        return spriteNames[rawValue - 1]
    }
    
    var highlightedSpriteName: String {
        return spriteName + "-Highlighted"
    }
    
    static func predefined(type: Int) -> CookieType {
        return CookieType(rawValue: type)!
    }
    
    var description: String {
        return spriteName
    }
}

class Cannon: Cookie {
    let cannonType: CannonType
    
    init(column: Int, row: Int, cannonType: CannonType, cookieType: CookieType) {
        self.cannonType = cannonType
        super.init(column: column, row: row, cookieType: cookieType)
    }
    
    override var description: String {
        return "Cannon square:(\(column),\(row))"
    }
    
    override var spriteName: String {
        return cookieType.spriteName + cannonType.spriteName
    }
}

func ==(lhs: Cannon, rhs: Cannon) -> Bool {
    return lhs.column == rhs.column && lhs.row == rhs.row
}

