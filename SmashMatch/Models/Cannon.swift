//
//  Cookie.swift
//  CookieCrunch
//
//  Created by Cameron Porter on 18/12/17.
//  Copyright © 2017 Cameron Porter. All rights reserved.
//

import SpriteKit

class Cannon: Cookie {
    
    init(column: Int, row: Int) {
        super.init(column: column, row: row, cookieType: CookieType(rawValue: 7)!)
    }
    
    override var description: String {
        return "Cannon square:(\(column),\(row))"
    }
}

func ==(lhs: Cannon, rhs: Cannon) -> Bool {
    return lhs.column == rhs.column && lhs.row == rhs.row
}

