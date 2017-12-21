//
//  Cookie.swift
//  CookieCrunch
//
//  Created by Cameron Porter on 18/12/17.
//  Copyright © 2017 Cameron Porter. All rights reserved.
//

import SpriteKit

enum CookieType: Int, CustomStringConvertible  {
    case unknown = 0, croissant, cupcake, danish, donut, macaroon, sugarCookie, wall
    var spriteName: String {
        let spriteNames = [
            "blue",
            "green",
            "orange",
            "pink",
            "yellow",
            "Wall"]
        
        return spriteNames[rawValue - 1]
    }
    
    var highlightedSpriteName: String {
        return spriteName + "-Highlighted"
    }
    
    static func random() -> CookieType {
        return CookieType(rawValue: Int(arc4random_uniform(5)) + 1)!
    }
    
    static func predefined(type: Int) -> CookieType {
        return CookieType(rawValue: type)!
    }
    
    var description: String {
        return spriteName
    }
}

class Cookie: CustomStringConvertible, Hashable {
    var column: Int
    var row: Int
    let cookieType: CookieType
    var sprite: SKSpriteNode?
    var moved: Bool = false; //Used for flaging possible cookies that could have caused chains (potential future cannons).
    
    init(column: Int, row: Int, cookieType: CookieType) {
        self.column = column
        self.row = row
        self.cookieType = cookieType
    }
    
    var hashValue: Int {
        return row*10 + column
    }
    
    var description: String {
        return "type:\(cookieType) square:(\(column),\(row))"
    }
    
    var spriteName: String {
        return cookieType.spriteName + "gem"
    }
}

func ==(lhs: Cookie, rhs: Cookie) -> Bool {
    return lhs.column == rhs.column && lhs.row == rhs.row
}
