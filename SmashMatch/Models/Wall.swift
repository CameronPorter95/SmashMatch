//
//  Cookie.swift
//  CookieCrunch
//
//  Created by Cameron Porter on 18/12/17.
//  Copyright © 2017 Cameron Porter. All rights reserved.
//

import SpriteKit

enum WallType: Int, CustomStringConvertible  {
    case unknown = 0, new, broken
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

class Wall: Cookie {
    let wallType: WallType
    
    init(column: Int, row: Int, wallType: WallType) {
        self.wallType = wallType
        super.init(column: column, row: row, cookieType: CookieType(rawValue: 8)!)
    }
    
    override var description: String {
        return "Wall square:(\(column),\(row))"
    }
}

func ==(lhs: Wall, rhs: Wall) -> Bool {
    return lhs.column == rhs.column && lhs.row == rhs.row
}

