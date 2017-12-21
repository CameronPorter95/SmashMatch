//
//  Swap.swift
//  SmashMatch
//
//  Created by Cameron Porter on 19/12/17.
//  Copyright © 2017 Cameron Porter. All rights reserved.
//

struct Swap: CustomStringConvertible, Hashable  {
    let gemA: Gem
    let gemB: Gem
    
    init(gemA: Gem, gemB: Gem) {
        self.gemA = gemA
        self.gemB = gemB
    }
    
    var description: String {
        return "swap \(gemA) with \(gemB)"
    }
    
    var hashValue: Int {
        return gemA.hashValue ^ gemB.hashValue
    }
}

func ==(lhs: Swap, rhs: Swap) -> Bool {
    return (lhs.gemA == rhs.gemA && lhs.gemB == rhs.gemB) ||
        (lhs.gemB == rhs.gemA && lhs.gemA == rhs.gemB)
}
