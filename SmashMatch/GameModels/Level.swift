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
    fileprivate var futureGems: Array2D<Gem>?
    private var tiles = Array2D<Tile>(columns: NumColumns, rows: NumRows)
    private var addedCannons = Set<Cannon>() //The cannons added for the current gameloop (gets reset every game loop, gems holds the cannons indefintely)
    private var walls = Set<Wall>()
    private var matchedCannons: Set<Cannon>?
    private var maxWalls = 5
    private var possibleSwaps = Set<Swap>()
    private var comboMultiplier = 0
    var targetScore = 0
    var maximumMoves = 0
    
    var gemsFromFileArray: [[Int]]?
    var futureGemsFromFileArray: [[Int]]?
    var numFutureGemRows = Int()
    var isClassicMode = true; //Set this based on the game mode
    var initialLoad = true;
    
    func shuffle() -> Set<Gem> {
        for wall in walls {
            print(wall.wallType)
        }
        print(walls.count)
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
    
    private func createInitialGems() -> Set<Gem> {
        var set = Set<Gem>()
        for row in 0..<NumRows {
            for column in 0..<NumColumns {
                if tiles[column, row] != nil {
                    if(row == 0 || row == NumRows-1 || column == 0 || column == NumColumns-1){
                        continue
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
        let possibleWallPositions = getPossibleWallPositions()
        for _ in 0..<maxWalls {
            if initialLoad == true {
                var positionIndex = Int(arc4random_uniform(32))
                if positionIndex == 7 || positionIndex == 31 { positionIndex = Int(arc4random_uniform(32)) }
                let wall: Wall
                if(possibleWallPositions[positionIndex][0] == 0 || possibleWallPositions[positionIndex][0] == NumRows-1) {
                    wall = Wall(column: possibleWallPositions[positionIndex][1], row: possibleWallPositions[positionIndex][0], wallType: WallType.new, horizontal: true)
                } else {
                    wall = Wall(column: possibleWallPositions[positionIndex][1], row: possibleWallPositions[positionIndex][0], wallType: WallType.new, horizontal: false)
                }
                gems[possibleWallPositions[positionIndex][1], possibleWallPositions[positionIndex][0]] = wall
                set.insert(wall)
                walls.insert(wall)
            }
        }
        initialLoad = false
        return set
    }
    
    private func createInitialGemsFromFile() -> Set<Gem> {
        futureGems = Array2D<Gem>(columns: NumColumns, rows: numFutureGemRows)
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
                        var gem = Gem(column: column, row: row, gemType: GemType(rawValue: gemType)!)
                        if gem.gemType.spriteName == "Cannon" {
                            gem = Cannon(column: column, row: row, cannonType: CannonType.fourWay, gemType: GemType.blue)
                        }
                        gems[column, row] = gem
                        set.insert(gem)
                    }
                }
            }
        }
        for row in 0..<numFutureGemRows {
            for column in 0..<NumColumns {
                if(column == 0 || column == NumColumns-1){
                    continue
                } else {
                    let gemType = futureGemsFromFileArray![row][column]
                    let gem = Gem(column: column, row: row, gemType: GemType(rawValue: gemType)!)
                    futureGems![column, row] = gem
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
        futureGemsFromFileArray = dictionary["futureGems"] as? [[Int]]
        numFutureGemRows = futureGemsFromFileArray!.count
        for (row, rowArray) in tilesArray.enumerated() {
            let tileRow = NumRows - row - 1
            for (column, value) in rowArray.enumerated() {
                if value == 1 {
                    if isClassicMode == false && (tileRow == 0 || tileRow == NumRows-1 || column == 0 || column == NumColumns-1) {
                        continue
                    }
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
        var horizontalChains = detectHorizontalMatches()
        var verticalChains = detectVerticalMatches()
        var interceptChains = Set<Chain>()
        
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
                        
                        let chain = Chain(chainType: .intercept)
                        horizontalChains.remove(horzChain)
                        verticalChains.remove(vertChain)
                        vertChain.remove(element: gem)
                        chain.add(chain: horzChain)
                        chain.add(chain: vertChain)
                        interceptChains.insert(chain)
                        continue
                    }
                }
            }
        }
        
        addedCannons = cannons
        removeGems(chains: horizontalChains)
        removeGems(chains: verticalChains)
        removeGems(chains: interceptChains)
        calculateScores(for: horizontalChains)
        calculateScores(for: verticalChains)
        calculateScores(for: interceptChains)
        
        for row in 0..<NumRows {
            for column in 0..<NumColumns {
                if tiles[column, row] != nil {
                    gems[column, row]?.moved = false;
                }
            }
        }
        return horizontalChains.union(verticalChains).union(interceptChains)
    }
    
    private func calculateScores(for chains: Set<Chain>) {
        // 3-chain is 60 pts, 4-chain is 120, 5-chain is 180, and so on
        for chain in chains { //TODO get points for setting off cannon and increase score multiplier based on cannon fire chain length
            chain.score = 60 * (chain.length - 2) * comboMultiplier //TODO always calculate either big or small chains first
            if chain.chainType == .intercept {
                chain.score = chain.score*2
            }
            comboMultiplier += 1
        }
    }
    
    func resetComboMultiplier() {
        comboMultiplier = 1
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
    
    //Returns a set of tiles hit by this cannonball
    func fireCannon(cannon: Cannon, direction: String) -> [Gem]? {
        var hitTiles = [Gem]()
        var curColumn = cannon.column+1
        var curRow = cannon.row
        while(curColumn < NumColumns && direction == "East") {
            if(gems[curColumn, curRow] is Cannon || gems[curColumn, curRow] is Wall) {
                let hitTile = gems[curColumn, curRow]
                if hitTile is Wall {
                    let wall = hitTile as! Wall
                    if wall.wallType == .broken {
                        wall.isDestroyed = true
                        tiles[curColumn, curRow] = nil
                        gems[curColumn, curRow] = nil
                        hitTiles.append(hitTile!)
                        break
                    } else {
                        wall.wallType = .broken
                        hitTiles.append(hitTile!)
                        break
                        //                        curColumn += 1
                        //                        if curColumn >= NumColumns { break }
                        //                        continue
                    }
                }
                gems[curColumn, curRow] = nil
                hitTiles.append(hitTile!)
            }
            if curColumn == NumColumns-1 {
                hitTiles.append(Gem(column: curColumn, row: curRow, gemType: .unknown))
            }
            curColumn += 1
        }
        curColumn = cannon.column-1
        curRow = cannon.row
        while(curColumn > -1 && direction == "West") {
            if(gems[curColumn, curRow] is Cannon || gems[curColumn, curRow] is Wall) {
                let hitTile = gems[curColumn, curRow]
                if hitTile is Wall {
                    let wall = hitTile as! Wall
                    if wall.wallType == .broken {
                        wall.isDestroyed = true
                        tiles[curColumn, curRow] = nil
                        gems[curColumn, curRow] = nil
                        hitTiles.append(hitTile!)
                        break
                    } else {
                        wall.wallType = .broken
                        hitTiles.append(hitTile!)
                        break
                        //                        curColumn -= 1
                        //                        if curColumn <= -1 { break }
                        //                        continue
                    }
                }
                gems[curColumn, curRow] = nil
                hitTiles.append(hitTile!)
            }
            if curColumn == 0 {
                hitTiles.append(Gem(column: curColumn, row: curRow, gemType: .unknown))
            }
            curColumn -= 1
        }
        curColumn = cannon.column
        curRow = cannon.row+1
        while(curRow < NumRows && direction == "North") {
            if(gems[curColumn, curRow] is Cannon || gems[curColumn, curRow] is Wall) {
                let hitTile = gems[curColumn, curRow]
                if hitTile is Wall {
                    let wall = hitTile as! Wall
                    if wall.wallType == .broken {
                        wall.isDestroyed = true
                        tiles[curColumn, curRow] = nil
                        gems[curColumn, curRow] = nil
                        hitTiles.append(hitTile!)
                        break
                    } else {
                        wall.wallType = .broken
                        hitTiles.append(hitTile!)
                        break
                        //                        curRow += 1
                        //                        if curRow >= NumRows { break }
                        //                        continue
                    }
                }
                gems[curColumn, curRow] = nil
                hitTiles.append(hitTile!)
            }
            if curRow == NumRows-1 {
                hitTiles.append(Gem(column: curColumn, row: curRow, gemType: .unknown))
            }
            curRow += 1
        }
        curColumn = cannon.column
        curRow = cannon.row-1
        while(curRow > -1 && direction == "South") {
            if(gems[curColumn, curRow] is Cannon || gems[curColumn, curRow] is Wall) {
                let hitTile = gems[curColumn, curRow]
                if hitTile is Wall {
                    let wall = hitTile as! Wall
                    if wall.wallType == .broken {
                        wall.isDestroyed = true
                        tiles[curColumn, curRow] = nil
                        gems[curColumn, curRow] = nil
                        hitTiles.append(hitTile!)
                        break
                    } else {
                        wall.wallType = .broken
                        hitTiles.append(hitTile!)
                        break
                        //                        curRow -= 1
                        //                        if curRow <= -1 { break }
                        //                        continue
                    }
                }
                gems[curColumn, curRow] = nil
                hitTiles.append(hitTile!)
            }
            if curRow == 0 {
                hitTiles.append(Gem(column: curColumn, row: curRow, gemType: .unknown))
            }
            curRow -= 1
        }
        return hitTiles
    }
    
    private func removeGems(chains: Set<Chain>) {
        for chain in chains {
            for gem in chain.gems {
                gems[gem.column, gem.row] = nil
            }
        }
    }
    
    func fillHoles() -> [[Gem]] {
        var numRows = NumRows
        var columns = [[Gem]]()
        for column in 0..<NumColumns {
            var array = [Gem]()
            var numHoles = 0
            if isClassicMode {
                numRows += numFutureGemRows
            }
            for row in 0..<NumRows-1 {
                if (tiles[column, row] != nil && gems[column, row] == nil) { //Only fill holes in the playavble grid. Filling holes in futureGems comes later
                    numHoles += 1
                    for lookup in (row + 1)..<numRows { //Scan upwards in search of gems to fill hole
                        if lookup<NumRows-1 { //If looking up to first 8 rows of grid
                            if let gem = gems[column, lookup] { //If found gem above current gem
//                                if(gem is Wall){
//                                    break
//                                }
                                gem.moved = true;
                                gems[column, lookup] = nil
                                gems[column, row] = gem
                                gem.row = row
                                array.append(gem)
                                break
                            }
                        } else { //If reached top row or above (i.e. looking above the grid) we need to jump to look for futureGems
                            var count = 0
                            for futureLookup in 0..<numFutureGemRows { //If lookup reaches top row, must grab futureGems for as many holes were formed (number of holes = number of futureGems required).
                                if(futureLookup >= (futureGems?.rows)! || count == numHoles){
                                    break
                                }
                                if let gem = futureGems![column, futureLookup] {
                                    gem.moved = true;
                                    futureGems![column, futureLookup] = nil
                                    gems[column, row] = gem
                                    gem.row = row
                                    array.append(gem)//TODO
                                    count += 1
                                    break
                                }
                            }
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
    
    func getWalls() -> Set<Wall>{
        return walls
    }
}

