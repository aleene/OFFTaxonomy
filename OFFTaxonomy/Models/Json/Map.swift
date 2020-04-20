//
//  Map.swift
//  Atlas
//
//  Created by arnaud on 17/04/2020.
//  Copyright © 2020 Hovering Above. All rights reserved.
//

import Foundation

class Map: Codable {
    
    var nodes: [String:CountryNode]?
    var edges: [String:[String:Border]]?
}
