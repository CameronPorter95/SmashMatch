//
//  Chain.swift
//  SmashMatch
//
//  An object that holds an array of gems included in a match that has been made,
//
//  Created by Cameron Porter on 19/12/17.
//  Copyright © 2017 Cameron Porter. All rights reserved.
//

class Chain: Hashable, CustomStringConvertible {
    var gems = [Gem]() //TODO if any of these gems exist in another chain as well, then that makes a 4 way cannon.
    var score = 0
    
    enum ChainType: CustomStringConvertible {
        case horizontal
        case vertical
        case intercept
        
        var description: String {
            switch self {
            case .horizontal: return "Horizontal"
            case .vertical: return "Vertical"
            case .intercept: return "Intercept"
            }
        }
    }
    
    var chainType: ChainType
    
    init(chainType: ChainType) {
        self.chainType = chainType
    }
    
    func add(gem: Gem) {
        gems.append(gem)
    }
    
    func add(chain: Chain) {
        gems += chain.gems
    }
    
    func remove(element: Gem) {
        gems = gems.filter() { $0 !== element }
    }
    
    func firstGem() -> Gem {
        return gems[0]
    }
    
    func lastGem() -> Gem {
        return gems[gems.count - 1]
    }
    
    var length: Int {
        return gems.count
    }
    
    var description: String {
        return "type:\(chainType) gems:\(gems)"
    }
    
    var hashValue: Int {
        return gems.reduce (0) { $0.hashValue ^ $1.hashValue }
    }
}

func ==(lhs: Chain, rhs: Chain) -> Bool {
    return lhs.gems == rhs.gems
}
