//
//  DataMapper.swift
//  SmashMatch
//
//  Created by Cameron Porter on 20/12/17.
//  Copyright © 2017 Cameron Porter. All rights reserved.
//

import SQLite

let db = try! Connection("path/to/db.sqlite3") //TODO maybe shouldn't be force unwrapped

//public func insertInto(table: Table, keys: [AnyObject]){
//    let insert = table.insert(name <- "Alice", email <- "alice@mac.com")
//    let rowid = try db.run(insert)
//}

//tables we need

//-settings
    //soundeffect mute, music mute

//-Lives
    //number of lives
    //time user stopped app

//-levels
    //array of grid + top 15 and walls

//leaderboards
    //highscore arcade
    //highscore demolition

//Progess
    //classic levels unlocked
