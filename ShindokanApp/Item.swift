//
//  Item.swift
//  ShindokanApp
//
//  Created by Mert Akdemir on 28.05.24.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
