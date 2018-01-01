//
//  Extensions.swift
//  SmashMatch
//
//  Created by Cameron Porter on 19/12/17.
//  Copyright © 2017 Cameron Porter. All rights reserved.
//

import Foundation

extension Dictionary {
    static func loadJSONFromBundle(filename: String) -> Dictionary<String, AnyObject>? {
        var dataOK: Data
        var dictionaryOK: NSDictionary = NSDictionary()
        if let path = Bundle.main.path(forResource: filename, ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: NSData.ReadingOptions()) as Data!
                dataOK = data!
            }
            catch {
                print("Could not load level file: \(filename), error: \(error)")
                return nil
            }
            do {
                let dictionary = try JSONSerialization.jsonObject(with: dataOK, options: JSONSerialization.ReadingOptions()) as AnyObject!
                dictionaryOK = (dictionary as! NSDictionary as? Dictionary<String, AnyObject>)! as NSDictionary
            }
            catch {
                print("Level file '\(filename)' is not valid JSON: \(error)")
                return nil
            }
        }
        return dictionaryOK as? Dictionary<String, AnyObject>
    }
}

extension Notification.Name {
    public static let arcadeButtonPressed = Notification.Name(rawValue: "arcadeButtonPressed")
    public static let classicButtonPressed = Notification.Name(rawValue: "classicButtonPressed")
    public static let demolitionButtonPressed = Notification.Name(rawValue: "demolitionButtonPressed")
    public static let creditsButtonPressed = Notification.Name(rawValue: "creditsButtonPressed")
    public static let backToMainMenu = Notification.Name(rawValue: "backToMainMenu")
    public static let shuffleButtonPressed = Notification.Name(rawValue: "shuffleButtonPressed")
}
