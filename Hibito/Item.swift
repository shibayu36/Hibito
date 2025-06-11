//
//  Item.swift
//  Hibito
//
//  Created by Yuki Shibazaki on 2025/06/11.
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