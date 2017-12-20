//
//  Cookie.swift
//  CookieCrunch
//
//  Created by Cameron Porter on 18/12/17.
//  Copyright © 2017 Cameron Porter. All rights reserved.
//

import SpriteKit

enum CannonType: Int, CustomStringConvertible  {
    case unknown = 0, twoWay, fourWay
    var spriteName: String {
        let spriteNames = [
            "Macaroon",
            "SugarCookie"]
        
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
    
    init(column: Int, row: Int, cannonType: CannonType) {
        self.cannonType = cannonType
        super.init(column: column, row: row, cookieType: CookieType(rawValue: 7)!)
    }
    
    override var description: String {
        return "Cannon square:(\(column),\(row))"
    }
}

func ==(lhs: Cannon, rhs: Cannon) -> Bool {
    return lhs.column == rhs.column && lhs.row == rhs.row
}

