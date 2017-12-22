//
//  Level.swift
//  SmashMatch
//
//  Created by Cameron Porter on 18/12/17.
//  Copyright © 2017 Cameron Porter. All rights reserved.
//

import Foundation

let NumColumns = 10
let NumRows = 10
let NumLevels = 4 // Excluding level 0

class Level {
    fileprivate var gems = Array2D<Gem>(columns: NumColumns, rows: NumRows)
    private var tiles = Array2D<Tile>(columns: NumColumns, rows: NumRows)
    private var addedCannons = Set<Cannon>() //The cannons added for the current gameloop (gets reset every game loop, gems holds the cannons indefintely)
    private var walls = Set<Wall>()
    private var matchedCannons: Set<Cannon>?
    private var maxWalls = 5
    private var possibleSwaps = Set<Swap>()
    var targetScore = 0
    var maximumMoves = 0
    
    var gemsFromFileArray: [[Int]]?
    var isClassicMode = true; //Set this based on the game mode
    var initialLoad = true;
    
    func shuffle() -> Set<Gem> {
        var set: Set<Gem>
        if(isClassicMode){
            set = createInitialGemsFromFile()
            _ = detectPossibleSwaps()
            isClassicMode = false;
            return set
        }
        repeat {
            set = createInitialGems()
            _ = detectPossibleSwaps()
//            print("possible swaps: \(possibleSwaps)")
        } while possibleSwaps.count == 0
        
        return set
    }
    
    private func calculateScores(for chains: Set<Chain>) {
        // 3-chain is 60 pts, 4-chain is 120, 5-chain is 180, and so on
        for chain in chains {
            chain.score = 60 * (chain.length - 2)
        }
    }
    
    private func createInitialGems() -> Set<Gem> {
        var set = Set<Gem>()
        let possibleWallPositions = getPossibleWallPositions()
        for row in 0..<NumRows {
            for column in 0..<NumColumns {
                if tiles[column, row] != nil {
                    if(row == 0 || row == NumRows-1 || column == 0 || column == NumColumns-1){
                        //Random place walls but only once
                        if walls.count < maxWalls && initialLoad == true {
                            let positionIndex = Int(arc4random_uniform(32))
                            let wall: Wall
                            if(possibleWallPositions[positionIndex][0] == 0 || possibleWallPositions[positionIndex][0] == NumRows-1) {
                                wall = Wall(column: possibleWallPositions[positionIndex][1], row: possibleWallPositions[positionIndex][0], wallType: WallType.new, horizontal: true)
                            } else {
                                wall = Wall(column: possibleWallPositions[positionIndex][1], row: possibleWallPositions[positionIndex][0], wallType: WallType.new, horizontal: false)
                            }
                            gems[column, row] = wall
                            set.insert(wall)
                            walls.insert(wall)
                            continue;
                        }
                    } else {
                        var gemType: GemType
                        repeat {
                            gemType = GemType.random()
                        } while (column >= 2 &&
                            gems[column - 1, row]?.gemType == gemType &&
                            gems[column - 2, row]?.gemType == gemType)
                            || (row >= 2 &&
                                gems[column, row - 1]?.gemType == gemType &&
                                gems[column, row - 2]?.gemType == gemType)
                        
                        let gem = Gem(column: column, row: row, gemType: gemType)
                        gems[column, row] = gem
                        set.insert(gem)
                    }
                }
            }
        }
        print(walls)
        initialLoad = false
        return set
    }
    
    private func createInitialGemsFromFile() -> Set<Gem> {
        var set = Set<Gem>()
        for row in 0..<NumRows {
            for column in 0..<NumColumns {
                if tiles[column, row] != nil {
                    if(row == 0 || row == NumRows-1 || column == 0 || column == NumColumns-1){
                        //Make a wall if underlying tile exists and on border
                        let wall: Wall
                        if(row == 0 || row == NumRows-1) {
                            wall = Wall(column: column, row: row, wallType: WallType.new, horizontal: true)
                        } else {
                            wall = Wall(column: column, row: row, wallType: WallType.new, horizontal: false)
                        }
                        gems[column, row] = wall
                        set.insert(wall)
                        walls.insert(wall)
                        continue;
                    } else {
                        let gemType = gemsFromFileArray![row][column]
                        let gem = Gem(column: column, row: row, gemType: GemType(rawValue: gemType)!)
                        gems[column, row] = gem
                        set.insert(gem)
                    }
                }
            }
        }
        initialLoad = false
        return set
    }
    
    init(filename: String) {
        guard let dictionary = Dictionary<String, AnyObject>.loadJSONFromBundle(filename: filename) else { return }
        guard let tilesArray = dictionary["tiles"] as? [[Int]] else { return }
        gemsFromFileArray = dictionary["gems"] as? [[Int]]
        for (row, rowArray) in tilesArray.enumerated() {
            let tileRow = NumRows - row - 1
            for (column, value) in rowArray.enumerated() {
                if value == 1 {
                    tiles[column, tileRow] = Tile()
                }
            }
        }
        targetScore = dictionary["targetScore"] as! Int
        maximumMoves = dictionary["moves"] as! Int
        
    }
    
    func getPossibleWallPositions() -> [[Int]] {
        var possibleWallPositions: [[Int]] = [[Int]]()
        for row in 0..<NumRows {
            for column in 0..<NumColumns {
                if(row == 0 || row == NumRows-1 || column == 0 || column == NumColumns-1){
                    if(row == 0 && column == 0 ||
                        row == NumRows-1 && column == 0 ||
                        row == 0 && column == NumColumns-1 ||
                        row == NumRows-1 && column == NumColumns-1){
                        continue;
                    }
                    possibleWallPositions.append([column, row])
                }
            }
        }
        return possibleWallPositions
    }
    
    func performSwap(swap: Swap) {
        let columnA = swap.gemA.column
        let rowA = swap.gemA.row
        let columnB = swap.gemB.column
        let rowB = swap.gemB.row
        
        gems[columnA, rowA] = swap.gemB
        swap.gemB.column = columnA
        swap.gemB.row = rowA
        
        gems[columnB, rowB] = swap.gemA
        swap.gemA.column = columnB
        swap.gemA.row = rowB
        swap.gemA.moved = true;
        swap.gemB.moved = true;
    }
    
    func gemAt(column: Int, row: Int) -> Gem? {
        assert(column >= 0 && column < NumColumns)
        assert(row >= 0 && row < NumRows)
        return gems[column, row]
    }
    
    func tileAt(column: Int, row: Int) -> Tile? {
        assert(column >= 0 && column < NumColumns)
        assert(row >= 0 && row < NumRows)
        return tiles[column, row]
    }
    
    func detectPossibleSwaps() -> Set<Swap>{
        var set = Set<Swap>()
        for row in 0..<NumRows {
            for column in 0..<NumColumns {
                if let gem = gems[column, row] {
                    if column < NumColumns - 1 {
                        if let other = gems[column + 1, row] {
                            gems[column, row] = other
                            gems[column + 1, row] = gem
                            if hasChainAt(column: column + 1, row: row) ||
                                hasChainAt(column: column, row: row) {
                                set.insert(Swap(gemA: gem, gemB: other))
                            }
                            gems[column, row] = gem
                            gems[column + 1, row] = other
                        }
                    }
                    if row < NumRows - 1 {
                        if let other = gems[column, row + 1] {
                            gems[column, row] = other
                            gems[column, row + 1] = gem
                            
                            // Is either gem now part of a chain?
                            if hasChainAt(column: column, row: row + 1) ||
                                hasChainAt(column: column, row: row) {
                                set.insert(Swap(gemA: gem, gemB: other))
                            }
                            
                            // Swap them back
                            gems[column, row] = gem
                            gems[column, row + 1] = other
                        }
                    }
                }
            }
        }
        possibleSwaps = set
        return possibleSwaps
    }
    
    func isPossibleSwap(_ swap: Swap) -> Bool {
        return possibleSwaps.contains(swap)
    }
    
    private func detectHorizontalMatches() -> Set<Chain> {
        var set = Set<Chain>()
        for row in 0..<NumRows {
            var column = 0
            while column < NumColumns-2 {
                if let gem = gems[column, row] {
                    let matchType = gem.gemType
                    if gems[column + 1, row]?.gemType == matchType &&
                        gems[column + 2, row]?.gemType == matchType {
                        let chain = Chain(chainType: .horizontal)
                        repeat {
                            chain.add(gem: gems[column, row]!)
                            column += 1
                        } while column < NumColumns && gems[column, row]?.gemType == matchType
                        
                        set.insert(chain)
                        continue
                    }
                }
                column += 1
            }
        }
        return set
    }
    
    private func detectVerticalMatches() -> Set<Chain> {
        var set = Set<Chain>()
        
        for column in 0..<NumColumns {
            var row = 0
            while row < NumRows-2 {
                if let gem = gems[column, row] {
                    let matchType = gem.gemType
                    
                    if gems[column, row + 1]?.gemType == matchType &&
                        gems[column, row + 2]?.gemType == matchType {
                        let chain = Chain(chainType: .vertical)
                        repeat {
                            chain.add(gem: gems[column, row]!)
                            row += 1
                        } while row < NumRows && gems[column, row]?.gemType == matchType
                        
                        set.insert(chain)
                        continue
                    }
                }
                row += 1
            }
        }
        return set
    }
    
    func removeMatches() -> Set<Chain> {
        let horizontalChains = detectHorizontalMatches()
        let verticalChains = detectVerticalMatches()
        
        var cannons = Set<Cannon>()
        //Get cannon positions from straight chains.
        createCannons(chains: horizontalChains, cannons: &cannons, isHorz: true)
        createCannons(chains: verticalChains, cannons: &cannons, isHorz: false)
        
        //Check for chain interceptions for L and T chains and create cannons from L and T's.
        for horzChain in horizontalChains {
            for vertChain in verticalChains {
                for gem in horzChain.gems {
                    if vertChain.gems.contains(gem) {
                        let cannon = Cannon(column: gem.column, row: gem.row, cannonType: CannonType.fourWay, gemType: gem.gemType)
                        if cannons.contains(cannon) {
                            cannons.remove(cannon)
                        }
                        cannons.insert(cannon)
                        print("Forming a 4 way intercept \(cannon.description) with type \(cannon.gemType.spriteName)\(cannon.cannonType.description)")
                    }
                }
            }
        }
        
        addedCannons = cannons
        matchedCannons = removeGems(chains: horizontalChains) //This sets cannons in matched cannons beforethe fillHoles method is called, potentially causing problems when firing the cannons as cannon moves beforehand.
        matchedCannons = matchedCannons?.union(removeGems(chains: verticalChains))
        //calculate the scorses
        calculateScores(for: horizontalChains)
        calculateScores(for: verticalChains)
        
        for row in 0..<NumRows {
            for column in 0..<NumColumns {
                if tiles[column, row] != nil {
                    gems[column, row]?.moved = false;
                }
            }
        }
        return horizontalChains.union(verticalChains)
        

    }
    
    func createCannons(chains: Set<Chain>, cannons: inout Set<Cannon>, isHorz: Bool) {
        for chain in chains {
            if(chain.length > 3){
                var chainGems = [Gem]() //The gems that moved to create this chain
                for gem in chain.gems {
                    if(gem.moved == true){
                        chainGems.append(gem)
                    }
                }
                var gem = chainGems[0]
                if(chainGems.count > 1){
                    if(isHorz){
                        if chainGems.last!.column < chain.lastGem().column {
                            gem = chainGems.last!
                        } else {
                            gem = chainGems.first!
                        }
                    } else {
                        gem = chainGems.first!
                    }
                }
                if(chain.length > 4){
                    let cannon = Cannon(column: gem.column, row: gem.row, cannonType: CannonType.fourWay, gemType: gem.gemType)
                    cannons.insert(cannon)
                    print("Forming a 4 Way\(cannon.description) with type \(cannon.gemType.spriteName)\(cannon.cannonType.description)")
                    break;
                }
                var cannon: Cannon
                if isHorz {
                    cannon = Cannon(column: gem.column, row: gem.row, cannonType: CannonType.twoWayHorz, gemType: gem.gemType)
                    print("Forming a 2 Way \(cannon.description) with type \(cannon.gemType.spriteName)\(cannon.cannonType.description)")
                }
                else {
                    cannon = Cannon(column: gem.column, row: gem.row, cannonType: CannonType.twoWayVert, gemType: gem.gemType)
                    print("Forming a 2 Way \(cannon.description) with type \(cannon.gemType.spriteName)\(cannon.cannonType.description)")
                }
                cannons.insert(cannon)
            }
        }
    }
    
    func getCannons() -> Set<Cannon>{
        for cannon in self.addedCannons {
            let column = cannon.column
            let row = cannon.row
            gems[column, row] = cannon
        }
        return self.addedCannons
    }
    
    func fireCannons(cannons: Set<Cannon>) -> Set<Cannon>? { //Returns a set of cannons hit by these cannons
        if(matchedCannons?.count == 0){
            return nil
        }
        var cannons = Set<Cannon>()
        for cannon in cannons {
            print(cannon.description)
            var curColumn = cannon.column
            var curRow = cannon.row
            while(curColumn < NumColumns-1 && cannon.cannonType != CannonType.twoWayVert) {
                if(gems[curColumn, curRow] is Cannon) {
                    let cannon = gems[curColumn, curRow] as! Cannon
                    //Found a cannon, recurse
                    gems[curColumn, curRow] = nil //Could be the wrong column and row as cannon has moved after being matched and before firing
                    cannons.insert(cannon)
                    //cannons = cannons.union(fireCannon(cannon: cannon))
                }
                curColumn += 1
            }
            while(curColumn > 0 && cannon.cannonType != CannonType.twoWayVert) {
                if(gems[curColumn, curRow] is Cannon) {
                    let cannon = gems[curColumn, curRow] as! Cannon
                    //Found a cannon, recurse
                    gems[curColumn, curRow] = nil
                    cannons.insert(cannon)
                    //cannons = cannons.union(fireCannon(cannon: cannon))
                }
                curColumn -= 1
            }
            while(curRow < NumRows-1 && cannon.cannonType != CannonType.twoWayHorz) {
                if(gems[curColumn, curRow] is Cannon) {
                    let cannon = gems[curColumn, curRow] as! Cannon
                    //Found a cannon, recurse
                    gems[curColumn, curRow] = nil
                    cannons.insert(cannon)
                    //cannons = cannons.union(fireCannon(cannon: cannon))
                }
                curRow += 1
            }
            while(curRow > 0 && cannon.cannonType != CannonType.twoWayHorz) {
                if(gems[curColumn, curRow] is Cannon) {
                    let cannon = gems[curColumn, curRow] as! Cannon
                    //Found a cannon, recurse
                    gems[curColumn, curRow] = nil
                    cannons.insert(cannon)
                    //cannons = cannons.union(fireCannon(cannon: cannon))
                }
                curRow -= 1
            }
        }
        return cannons
    }
    
    private func removeGems(chains: Set<Chain>) -> Set<Cannon>{ //Returns a set of cannons contained in the matched chains
        var cannons = Set<Cannon>()
        for chain in chains {
            for gem in chain.gems {
                if gem is Cannon {
                    let cannon = gem as! Cannon
                    cannons.insert(cannon)
                    gems[gem.column, gem.row] = nil
                    continue;
                } else {
                    gems[gem.column, gem.row] = nil //Not ready to remvove the cannons from the model yet
                }
            }
        }
        return cannons
    }
    
    func getMatchedCannons() -> Set<Cannon> {
        return matchedCannons!
    }
//    func removeCannons() -> Set<Cannon>{
//        var firedCannons = Set<Cannon>()
//        for cannon in matchedCannons {
//            firedCannons = firedCannons.union(fireCannon(cannon: cannon))
//            gems[cannon.column, cannon.row] = nil
//            continue;
//        }
//        return firedCannons
//    }
    
    func fillHoles() -> [[Gem]] {
        var columns = [[Gem]]()
        for column in 0..<NumColumns {
            var array = [Gem]()
            for row in 0..<NumRows {
                if tiles[column, row] != nil && gems[column, row] == nil {
                    for lookup in (row + 1)..<NumRows {
                        if let gem = gems[column, lookup] {
                            if(gem is Wall){
                                break
                            }
                            gem.moved = true;
                            gems[column, lookup] = nil
                            gems[column, row] = gem
                            gem.row = row
                            array.append(gem)
                            break
                        }
                    }
                }
            }
            if !array.isEmpty {
                columns.append(array)
            }
        }
        return columns
    }
    
    func topUpGems() -> [[Gem]] {
        var columns = [[Gem]]()
        var gemType: GemType = .unknown
        
        for column in 1..<NumColumns-1 {
            var array = [Gem]()
            var row = NumRows - 2
            while row >= 0 && gems[column, row] == nil {
                if tiles[column, row] != nil {
                    var newGemType: GemType
                    repeat {
                        newGemType = GemType.random()
                    } while newGemType == gemType
                    gemType = newGemType
                    let gem = Gem(column: column, row: row, gemType: gemType)
                    gem.moved = true
                    gems[column, row] = gem
                    array.append(gem)
                }
                
                row -= 1
            }
            if !array.isEmpty {
                columns.append(array)
            }
        }
        return columns
    }
    
    private func hasChainAt(column: Int, row: Int) -> Bool {
        let gemType = gems[column, row]!.gemType
        var horzLength = 1
        // Left
        var i = column - 1
        while i >= 0 && gems[i, row]?.gemType == gemType {
            i -= 1
            horzLength += 1
        }
        // Right
        i = column + 1
        while i < NumColumns && gems[i, row]?.gemType == gemType {
            i += 1
            horzLength += 1
        }
        if horzLength >= 3 { return true }
        
        var vertLength = 1
        // Down
        i = row - 1
        while i >= 0 && gems[column, i]?.gemType == gemType {
            i -= 1
            vertLength += 1
        }
        // Up
        i = row + 1
        while i < NumRows && gems[column, i]?.gemType == gemType {
            i += 1
            vertLength += 1
        }
        return vertLength >= 3
    }
}
