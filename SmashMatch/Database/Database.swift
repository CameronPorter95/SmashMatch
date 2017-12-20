//
//  Database.swift
//  SmashMatch
//
//  Created by Cameron Porter on 20/12/17.
//  Copyright © 2017 Cameron Porter. All rights reserved.
//

import Foundation
import SQLite

class Database {
    static let shared = Database()
    public let connection: Connection?
    public let databaseFileName = "db.sqlite3"
    private init(){
        let dbPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first as String!
        do {
            connection = try Connection("\(dbPath!)/(databaseFileName)")
        } catch {
            connection = nil
            let nserror = error as NSError
            print("Cannot connect to database. Error is: \(nserror), \(nserror.userInfo)")
        }
    }
}
