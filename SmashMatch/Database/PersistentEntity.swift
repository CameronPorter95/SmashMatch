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
            } else {
                print("Create table wrapper tblpersistent failed")
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
    
    //UPDATE tblPersistent SET(id= ... and soundEffectsEnabled = ... and ...) WHERE id == ??
    func update(id: Int64, soundEffectsEnabled: Bool?, musicEnabled: Bool?, numberOfLives: Int64?, timeStopped: Int64?,
                displayAds: Bool?, highscoreArcade: Int64?, highscoreDemolition: Int64?, highestLevelAchieved: Int64?) -> Bool {
        if Database.shared.connection == nil {
            return false
        }
        do {
            let tblFilterPersistent = self.tblPersistent.filter(self.id == id)
            var setters:[SQLite.Setter] = [SQLite.Setter]()
            if soundEffectsEnabled != nil {
                setters.append(self.soundEffectsEnabled <- soundEffectsEnabled!)
            }
            if musicEnabled != nil {
                setters.append(self.musicEnabled <- musicEnabled!)
            }
            if numberOfLives != nil {
                setters.append(self.numberOfLives <- numberOfLives!)
            }
            if timeStopped != nil {
                setters.append(self.timeStopped <- timeStopped!)
            }
            if displayAds != nil {
                setters.append(self.displayAds <- displayAds!)
            }
            if highscoreArcade != nil {
                setters.append(self.highscoreArcade <- highscoreArcade!)
            }
            if highscoreDemolition != nil {
                setters.append(self.highscoreDemolition <- highscoreDemolition!)
            }
            if highestLevelAchieved != nil {
                setters.append(self.highestLevelAchieved <- highestLevelAchieved!)
            }
            if setters.count == 0  {
                print("Nothing to update")
                return false
            }
            let update = tblFilterPersistent.update(setters)
            if try Database.shared.connection!.run(update) <= 0 {
                //Update unsuccessful
                return false
            }
            return true
        } catch {
            let nserror = error as NSError
            print("Cannot update objects in tblPersistent. Error is: \(nserror), \(nserror.userInfo)")
            return false
        }
    }
    
    func updateAt(id: Int64, index: Int, value: AnyObject) -> Bool {
        if Database.shared.connection == nil {
            return false
        }
        do {
            let tblFilterPersistent = self.tblPersistent.filter(self.id == id)
            var setters:[SQLite.Setter] = [SQLite.Setter]()
            if index == 2 {
                setters.append(self.soundEffectsEnabled <- soundEffectsEnabled)
            }
            if index == 3 {
                setters.append(self.musicEnabled <- musicEnabled)
            }
            if index == 4 {
                setters.append(self.numberOfLives <- numberOfLives)
            }
            if index == 5 {
                setters.append(self.timeStopped <- timeStopped)
            }
            if index == 6 {
                setters.append(self.displayAds <- displayAds)
            }
            if index == 7 {
                setters.append(self.highscoreArcade <- highscoreArcade)
            }
            if index == 8 {
                setters.append(self.highscoreDemolition <- highscoreDemolition)
            }
            if index == 9 {
                setters.append(self.highestLevelAchieved <- highestLevelAchieved)
            }
            if setters.count == 0  {
                print("Nothing to update")
                return false
            }
            let update = tblFilterPersistent.update(setters)
            if try Database.shared.connection!.run(update) <= 0 {
                //Update unsuccessful
                return false
            }
            return true
        } catch {
            let nserror = error as NSError
            print("Cannot update objects in tblPersistent. Error is: \(nserror), \(nserror.userInfo)")
            return false
        }
    }
    
    func queryFirst() -> AnySequence<Row>? {
        do {
            return try Database.shared.connection?.prepare(self.tblPersistent.filter(self.id == 1))
        } catch {
            let nserror = error as NSError
            print("Cannot query all tblPersistent. Error is: \(nserror), \(nserror.userInfo)")
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
    
    func toString(persistent: Row) {
        let tableDescription = """
            Persistent details. id = \(persistent[self.id]), \
            soundEffectsEnabled = \(persistent[self.soundEffectsEnabled]),
            musicEnabled = \(persistent[self.musicEnabled]),
            numberOfLives = \(persistent[self.numberOfLives]),
            timeStopped = \(persistent[self.timeStopped]),
            displayAds = \(persistent[self.displayAds]),
            highscoreArcade = \(persistent[self.highscoreArcade]),
            highscoreDemolition = \(persistent[self.highscoreDemolition]),
            highestLevelAchieved = \(persistent[self.highestLevelAchieved]))
            """
        
        print(tableDescription)
    }
    
    func getKeyAt(persistent: Row, index: Int) -> AnyObject? {
        switch index {
            case 1:
                return persistent[self.id] as AnyObject
            case 2:
                return persistent[self.soundEffectsEnabled] as AnyObject
            case 3:
                return persistent[self.musicEnabled] as AnyObject
            case 4:
                return persistent[self.numberOfLives] as AnyObject
            case 5:
                return persistent[self.timeStopped] as AnyObject
            case 6:
                return persistent[self.displayAds] as AnyObject
            case 7:
                return persistent[self.highscoreArcade] as AnyObject
            case 8:
                return persistent[self.highscoreDemolition] as AnyObject
            case 8:
                return persistent[self.highestLevelAchieved] as AnyObject
        default:
            return nil
        }
    }
    
    func hasRow(persistent: Row) -> Bool {
        let id = "\(persistent[self.id])"
        return id != ""
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
