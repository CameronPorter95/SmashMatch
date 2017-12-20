//
//  PersistentEntity.swift
//  SmashMatch
//
//  Created by Cameron Porter on 20/12/17.
//  Copyright © 2017 Cameron Porter. All rights reserved.
//

import Foundation
import SQLite

class PersistentEntity {
    static let shared = PersistentEntity()
    
    private let tblPersistent = Table("tblPersistent")
    
    private let id = Expression<Int64>("id")
    private let soundEffectsEnabled = Expression<Bool>("soundEffectsEnabled")
    private let musicEnabled = Expression<Bool>("musicEnabled")
    private let numberOfLives = Expression<Int64>("numberOfLives")
    private let timeStopped = Expression<Int64>("timeStopped") //TODO investigate storing timestamp in sqlite
    private let displayAds = Expression<Bool>("displayAds")
    private let highscoreArcade = Expression<Int64>("highscoreArcade")
    private let highscoreDemolition = Expression<Int64>("highscoreDemolition")
    private let highestLevelAchieved = Expression<Int64>("ihighestLevelAchievedd")
    
    private init() {
        //Create table if not exist
        do {
            if let connection = Database.shared.connection {
                try connection.run(tblPersistent.create(temporary: false, ifNotExists: true, withoutRowid: false, block: { (table) in
                    table.column(self.id, primaryKey: true)
                    table.column(self.soundEffectsEnabled)
                    table.column(self.musicEnabled)
                    table.column(self.numberOfLives)
                    table.column(self.timeStopped)
                    table.column(self.displayAds)
                    table.column(self.highscoreArcade)
                    table.column(self.highscoreDemolition)
                    table.column(self.highestLevelAchieved)
                }))
                print("Created table tblpersistent successfully")
            } else {
                print("Create table tblpersistent failed")
            }
        } catch {
            let nserror = error as NSError
            print("Create table tblPersistent failed. Error is: \(nserror), \(nserror.userInfo)")
        }
    }
    
    func insert(soundEffectsEnabled: Bool, musicEnabled: Bool, numberOfLives: Int64, timeStopped: Int64,
                displayAds: Bool, highscoreArcade: Int64, highscoreDemolition: Int64, highestLevelAchieved: Int64) -> Int64? {
        do {
            let insert = tblPersistent.insert(self.soundEffectsEnabled <- soundEffectsEnabled,
                                              self.musicEnabled <- musicEnabled,
                                              self.numberOfLives <- numberOfLives,
                                              self.timeStopped <- timeStopped,
                                              self.displayAds <- displayAds,
                                              self.highscoreArcade <- highscoreArcade,
                                              self.highscoreDemolition <- highscoreDemolition,
                                              self.highestLevelAchieved <- highestLevelAchieved)
            
            let insertedId = try Database.shared.connection!.run(insert)
            return insertedId
        } catch {
            let nserror = error as NSError
            print("Cannot insert new persistent. Error is: \(nserror), \(nserror.userInfo)")
            return nil
        }
    }
    
    func queryAll() -> AnySequence<Row>? {
        do {
            return try Database.shared.connection?.prepare(self.tblPersistent)
        } catch {
            let nserror = error as NSError
            print("Cannot query all tblPersistent. Error is: \(nserror), \(nserror.userInfo)")
            return nil
        }
    }
    
    func toString(persistent: Row){
        print("""
            Persistent details. soundEffectsEnabled = \(persistent[self.soundEffectsEnabled]), \
            musicEnabled = \(persistent[self.musicEnabled]),
            numberOfLives = \(persistent[self.numberOfLives]),
            timeStopped = \(persistent[self.timeStopped]),
            timeStopped = \(persistent[self.timeStopped]),
            displayAds = \(persistent[self.displayAds]),
            highscoreArcade = \(persistent[self.highscoreArcade]),
            highscoreDemolition = \(persistent[self.highscoreDemolition]),
            highestLevelAchieved = \(persistent[self.highestLevelAchieved]))
            """)
    }
}

//tables we need

//-settings
//soundeffect mute, music mute

//-Lives
//number of lives
//time user stopped app
//displayads

//-levels
//array of grid + top 15 and walls

//leaderboards
//highscore arcade
//highscore demolition

//Progess
//classic levels unlocked
