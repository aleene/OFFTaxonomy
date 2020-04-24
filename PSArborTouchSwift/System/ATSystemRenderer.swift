//
//  ATSystemRenderer.swift
//  PSArborTouch
//
//  Created by Ed Preston on 27/09/11.
//  Copyright 2015 Preston Software. All rights reserved.
//
//  Translated to Swift by Arnaud Leene on 03/04/2020.
//  Copyright © 2020 Hovering Above. All rights reserved.

//#import <Foundation/Foundation.h>

// Rendering protocols here.  Called in this order.
//      - Debug Rendering
//      - Edge Rendering
//      - Node Rendering



// Edge Rendering
//      - Edge
//      - Translated source point
//      - Translated target point


// Node Rendering
//      - Node
//      - Translated point


// Debug Rendering
//      - Barnes-Hut trees
//      - Bounds (physics and viewport)

public protocol ATDebugRendering {

    func redraw()
}

