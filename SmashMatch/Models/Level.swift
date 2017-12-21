//
//  Level.swift
//  CookieCrunch
//
//  Created by Cameron Porter on 18/12/17.
//  Copyright © 2017 Cameron Porter. All rights reserved.
//

import Foundation

let NumColumns = 10
let NumRows = 10
let NumLevels = 4 // Excluding level 0

class Level {
    fileprivate var cookies = Array2D<Cookie>(columns: NumColumns, rows: NumRows)
    private var tiles = Array2D<Tile>(columns: NumColumns, rows: NumRows)
    private var cannons = Set<Cannon>()
    private var walls = Set<Wall>()
    private var maxWalls = 5
    private var possibleSwaps = Set<Swap>()
    var targetScore = 0
    var maximumMoves = 0
    
    var cookiesFromFileArray: [[Int]]?
    var isClassicMode = false; //Set this based on the game mode
    var initialLoad = true;
    
    func shuffle() -> Set<Cookie> {
        var set: Set<Cookie>
        if(isClassicMode){
            set = createInitialCookiesFromFile()
            _ = detectPossibleSwaps()
            isClassicMode = false;
            return set
        }
        repeat {
            set = createInitialCookies()
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
    
    private func createInitialCookies() -> Set<Cookie> {
        var set = Set<Cookie>()
        let possibleWallPositions = getPossibleWallPositions()
        for row in 0..<NumRows {
            for column in 0..<NumColumns {
                if tiles[column, row] != nil {
                    if(row == 0 || row == NumRows-1 || column == 0 || column == NumColumns-1){
                        //Random place walls but only once
                        if walls.count < maxWalls && initialLoad == true {
                            let positionIndex = Int(arc4random_uniform(32))
                            let wall = Wall(column: possibleWallPositions[positionIndex][0], row: possibleWallPositions[positionIndex][1], wallType: WallType.new)
                            cookies[column, row] = wall
                            set.insert(wall)
                            walls.insert(wall)
                            continue;
                        }
                    } else {
                        var cookieType: CookieType
                        repeat {
                            cookieType = CookieType.random()
                        } while (column >= 2 &&
                            cookies[column - 1, row]?.cookieType == cookieType &&
                            cookies[column - 2, row]?.cookieType == cookieType)
                            || (row >= 2 &&
                                cookies[column, row - 1]?.cookieType == cookieType &&
                                cookies[column, row - 2]?.cookieType == cookieType)
                        
                        let cookie = Cookie(column: column, row: row, cookieType: cookieType)
                        cookies[column, row] = cookie
                        set.insert(cookie)
                    }
                }
            }
        }
        initialLoad = false
        return set
    }
    
    private func createInitialCookiesFromFile() -> Set<Cookie> {
        var set = Set<Cookie>()
        for row in 0..<NumRows {
            for column in 0..<NumColumns {
                if tiles[column, row] != nil {
                    if(row == 0 || row == NumRows-1 || column == 0 || column == NumColumns-1){
                        //Make a wall if underlying tile exists and on border
                        let wall = Wall(column: column, row: row, wallType: WallType.new)
                        cookies[column, row] = wall
                        set.insert(wall)
                        continue;
                    } else {
                        let cookieType = cookiesFromFileArray![row][column]
                        let cookie = Cookie(column: column, row: row, cookieType: CookieType(rawValue: cookieType)!)
                        cookies[column, row] = cookie
                        set.insert(cookie)
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
        cookiesFromFileArray = dictionary["cookies"] as? [[Int]]
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
        let columnA = swap.cookieA.column
        let rowA = swap.cookieA.row
        let columnB = swap.cookieB.column
        let rowB = swap.cookieB.row
        
        cookies[columnA, rowA] = swap.cookieB
        swap.cookieB.column = columnA
        swap.cookieB.row = rowA
        
        cookies[columnB, rowB] = swap.cookieA
        swap.cookieA.column = columnB
        swap.cookieA.row = rowB
        swap.cookieA.moved = true;
        swap.cookieB.moved = true;
    }
    
    func cookieAt(column: Int, row: Int) -> Cookie? {
        assert(column >= 0 && column < NumColumns)
        assert(row >= 0 && row < NumRows)
        return cookies[column, row]
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
                if let cookie = cookies[column, row] {
                    if column < NumColumns - 1 {
                        if let other = cookies[column + 1, row] {
                            cookies[column, row] = other
                            cookies[column + 1, row] = cookie
                            if hasChainAt(column: column + 1, row: row) ||
                                hasChainAt(column: column, row: row) {
                                set.insert(Swap(cookieA: cookie, cookieB: other))
                            }
                            cookies[column, row] = cookie
                            cookies[column + 1, row] = other
                        }
                    }
                    if row < NumRows - 1 {
                        if let other = cookies[column, row + 1] {
                            cookies[column, row] = other
                            cookies[column, row + 1] = cookie
                            
                            // Is either cookie now part of a chain?
                            if hasChainAt(column: column, row: row + 1) ||
                                hasChainAt(column: column, row: row) {
                                set.insert(Swap(cookieA: cookie, cookieB: other))
                            }
                            
                            // Swap them back
                            cookies[column, row] = cookie
                            cookies[column, row + 1] = other
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
                if let cookie = cookies[column, row] {
                    let matchType = cookie.cookieType
                    if cookies[column + 1, row]?.cookieType == matchType &&
                        cookies[column + 2, row]?.cookieType == matchType {
                        let chain = Chain(chainType: .horizontal)
                        repeat {
                            chain.add(cookie: cookies[column, row]!)
                            column += 1
                        } while column < NumColumns && cookies[column, row]?.cookieType == matchType
                        
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
                if let cookie = cookies[column, row] {
                    let matchType = cookie.cookieType
                    
                    if cookies[column, row + 1]?.cookieType == matchType &&
                        cookies[column, row + 2]?.cookieType == matchType {
                        let chain = Chain(chainType: .vertical)
                        repeat {
                            chain.add(cookie: cookies[column, row]!)
                            row += 1
                        } while row < NumRows && cookies[column, row]?.cookieType == matchType
                        
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
                for cookie in horzChain.cookies {
                    if vertChain.cookies.contains(cookie) {
                        let cannon = Cannon(column: cookie.column, row: cookie.row, cannonType: CannonType.fourWay, cookieType: cookie.cookieType)
                        if cannons.contains(cannon) {
                            cannons.remove(cannon)
                        }
                        cannons.insert(cannon)
                        print("Forming a 4 way intercept \(cannon.description) with type \(cannon.cannonType.description)")
                    }
                }
            }
        }
        
        self.cannons = cannons
        removeCookies(chains: horizontalChains)
        removeCookies(chains: verticalChains)
        
        for row in 0..<NumRows {
            for column in 0..<NumColumns {
                if tiles[column, row] != nil {
                    cookies[column, row]?.moved = false;
                }
            }
        }
        return horizontalChains.union(verticalChains)
        
        
        //calculate the scorses
        calculateScores(for: horizontalChains)
        calculateScores(for: verticalChains)
    }
    
    func createCannons(chains: Set<Chain>, cannons: inout Set<Cannon>, isHorz: Bool) {
        for chain in chains {
            if(chain.length > 3){
                for cookie in chain.cookies {
                    if(cookie.moved == true){
                        if(chain.length > 4){
                            let cannon = Cannon(column: cookie.column, row: cookie.row, cannonType: CannonType.fourWay, cookieType: cookie.cookieType)
                            cannons.insert(cannon)
                            print("Forming a 4 Way\(cannon.description) with type \(cannon.cannonType.description)")
                            break;
                        }
                        var cannon: Cannon
                        if isHorz {
                            cannon = Cannon(column: cookie.column, row: cookie.row, cannonType: CannonType.twoWayHorz, cookieType: cookie.cookieType)
                            print("Forming a 2 Way \(cannon.description) with type \(cannon.cannonType.description)")
                        }
                        else {
                            cannon = Cannon(column: cookie.column, row: cookie.row, cannonType: CannonType.twoWayVert, cookieType: cookie.cookieType)
                            print("Forming a 2 Way \(cannon.description) with type \(cannon.cannonType.description)")
                        }
                        cannons.insert(cannon)
                    }
                }
            }
        }
    }
    
    func getCannons() -> Set<Cannon>{
        for cannon in self.cannons {
            let column = cannon.column
            let row = cannon.row
            cookies[column, row] = cannon
        }
        return self.cannons
    }
    
    private func removeCookies(chains: Set<Chain>) {
        for chain in chains {
            for cookie in chain.cookies {
                cookies[cookie.column, cookie.row] = nil
            }
        }
    }
    
    func fillHoles() -> [[Cookie]] {
        var columns = [[Cookie]]()
        for column in 0..<NumColumns {
            var array = [Cookie]()
            for row in 0..<NumRows {
                if tiles[column, row] != nil && cookies[column, row] == nil {
                    for lookup in (row + 1)..<NumRows {
                        if let cookie = cookies[column, lookup] {
                            if(cookie is Wall){
                                break
                            }
                            cookie.moved = true;
                            cookies[column, lookup] = nil
                            cookies[column, row] = cookie
                            cookie.row = row
                            array.append(cookie)
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
    
    func topUpCookies() -> [[Cookie]] {
        var columns = [[Cookie]]()
        var cookieType: CookieType = .unknown
        
        for column in 0..<NumColumns {
            var array = [Cookie]()
            var row = NumRows - 2
            while row >= 0 && cookies[column, row] == nil {
                if tiles[column, row] != nil {
                    var newCookieType: CookieType
                    repeat {
                        newCookieType = CookieType.random()
                    } while newCookieType == cookieType
                    cookieType = newCookieType
                    let cookie = Cookie(column: column, row: row, cookieType: cookieType)
                    cookie.moved = true
                    cookies[column, row] = cookie
                    array.append(cookie)
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
        let cookieType = cookies[column, row]!.cookieType
        var horzLength = 1
        // Left
        var i = column - 1
        while i >= 0 && cookies[i, row]?.cookieType == cookieType {
            i -= 1
            horzLength += 1
        }
        // Right
        i = column + 1
        while i < NumColumns && cookies[i, row]?.cookieType == cookieType {
            i += 1
            horzLength += 1
        }
        if horzLength >= 3 { return true }
        
        var vertLength = 1
        // Down
        i = row - 1
        while i >= 0 && cookies[column, i]?.cookieType == cookieType {
            i -= 1
            vertLength += 1
        }
        // Up
        i = row + 1
        while i < NumRows && cookies[column, i]?.cookieType == cookieType {
            i += 1
            vertLength += 1
        }
        return vertLength >= 3
    }
}
