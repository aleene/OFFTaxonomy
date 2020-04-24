//
//  ATKernel.swift
//  SystemRig - System Test / Debug Rig
//
//  Created by Ed Preston on 26/09/11.
//  Copyright 2015 Preston Software. All rights reserved.
//
//  Created by arnaud on 02/04/2020.
//  Copyright © 2020 Hovering Above. All rights reserved.
//

import CoreGraphics
import Foundation

public class ATKernel {

//MARK: - Rendering

    public var delegate: ATDebugRendering?
    
// MARK: - - Rendering (override in subclass)

    public func updateViewPort() -> Bool {
        return false
    }

    /// _physicsIsDone indicates whether the physics algoritm has converged
    private var _physicsIsDone = true

    public func stepSimulation() {
        // step physics
                                
        // Run physics loop.
        // isStillActive indicates whether either the physics or the viewPort are still converging
        var isStillActive = false
        
        // If the physics is still converging, stay active
        // and do a next run
        if !_physicsIsDone {
            _physicsIsDone = !_physics.isUpdated()
            isStillActive = _physicsIsDone
        }
                
        // Update the viewport
        if updateViewPort() {
            isStillActive = true
        }
                
        // Stop timer if not stillActive.
        if !isStillActive {
            stop()
        }
                
        // Call back to main thread (UI Thread) to update the text
        // Dispatch SYNC or ASYNC here?  Could we queue too many updates?
        DispatchQueue.main.async(execute: { () -> Void in
                    
                    // Update cached properties
                    //
                    //      - Energy in the simulation
                    //      - Bounds of the simulation
            
            let currentEnergy = self.physics.energy
            self._simulationEnergy.sum = currentEnergy.sum
            self._simulationEnergy.max = currentEnergy.max
            self._simulationEnergy.mean = currentEnergy.mean
            self._simulationEnergy.count = currentEnergy.count
                    
            self._simulationBounds = self.physics.bounds
                    
                // Call back into the main thread
            
                //      - Update the debug barnes-hut display
                //      - Update the debug bounds display
                //      - Update the debug viewport display
                //      - Update the edge display
                //      - Update the node display
                        
            self.delegate?.redraw()
        });
    }
    
    public func start(unpause: Bool) {
        if _isRunning { return }
        // we've been stopped before, wait for unpause
        if _isPaused && !unpause { return }
        _isPaused = false
        // The physics engine will be restarted
        _physicsIsDone = false
        // start the simulation
        
        if !_isRunning {
            _isRunning = true
            
            // Configure handler when it fires
            physicsTimer()?.setEventHandler(handler: {
                // Call back to main thread (UI Thread) to update the text
                self.stepSimulation()
            });
            
            // Start the timer
            physicsTimer()?.resume()
        }
        
        print("ATKernel.start(unpause:) - Kernel started.")

    }

    public func stop() {
        // stop the simulation
        _isPaused = true
        
        if physicsTimer() != nil && _isRunning {
            _isRunning = false
            physicsTimer()?.suspend()
        }
        print("ATKernel:stop() - Kernel stopped.")
    }

//MARK: - initialisers
    
    init() { }

    init(speedLimit: CGFloat,
         deltaTime: CGFloat,
         stiffness: CGFloat,
         repulsion: CGFloat,
         friction: CGFloat,
         gravity: Bool,
         useBarnesHut: Bool,
         theta: CGFloat) {
    }
    
    public func setupPhysics(speedLimit: CGFloat,
                             deltaTime: CGFloat,
                             stiffness: CGFloat,
                             repulsion: CGFloat,
                             friction: CGFloat,
                             gravity: Bool,
                             useBarnesHut: Bool,
                             theta: CGFloat) {
        _physics.speedLimit = speedLimit
        _physics.deltaTime = deltaTime
        _physics.stiffness = stiffness
        _physics.repulsion = repulsion
        _physics.friction = friction
        _physics.gravity = gravity
        _physics.useBarnesHut = useBarnesHut
        _physics.theta = theta
    }
    
//MARK: - Debug Physics Properties

    public var physics: ATPhysics {
        _physics
    }

    public func dealloc() {
        delegate = nil;
        
        // stop the simulation
        stop()
        
        // tear down the timer
        physicsTimer()?.cancel()
        physicsTimer()?.resume()
    }

//MARK: - Cached Physics Properties
    
// We cache certain properties to provide information while the physics simulation is running.

    public var simulationEnergy: ATEnergy? {
        _simulationEnergy
    }

    public var simulationBounds: CGRect {
        _simulationBounds
    }

    private var _physics = ATPhysics()
    private var _simulationEnergy = ATEnergy()
    private var _simulationBounds: CGRect = CGRect(x: -1.0, y: -1.0, width: 2.0, height: 2.0)
    
//MARK: - Protected Physics Interface

// Physics methods protected by a GCD queue to ensure serial execution.
//TODO: Move into protocol / interface definition

    public func updateSimulation(params: ATSystemParams?) {
        //assert(params != nil, "ATKernel.updateSimulation - parameters nil")
        guard let validParams = params else { return }

        physicsQueue()?.async(execute: {
            self._physics.repulsion = validParams.repulsion
            self._physics.stiffness = validParams.stiffness
            self._physics.friction = validParams.friction
            self._physics.deltaTime = validParams.deltaTime
            self._physics.gravity = validParams.gravity
            self._physics.theta = validParams.theta
            self._physics.useBarnesHut = validParams.useBarnesHut
            self._physics.speedLimit = validParams.speedLimit
        });

    }

    public func add(particle: ATParticle?) {
        //assert(particle != nil, "ATKernel.add(particle:) - particle is nil")
        guard let validParticle = particle else { return }

        physicsQueue()?.async(execute: {
            self._physics.add(particle: validParticle)
        })
    }

    public func remove(particle: ATParticle?) {
        //assert(particle != nil, "ATKernel.remove(particle:) - particle is nil")
        guard let validParticle = particle else { return }
        
        physicsQueue()?.async(execute: {
            self._physics.remove(particle: validParticle)
        });
    }

    public func add(spring: ATSpring?) {
        //assert(spring != nil, "ATKernel.add(spring:) - spring is nil")
        guard let validSpring = spring else { return }

        physicsQueue()?.async(execute: {
            self._physics.add(spring: validSpring)
        });
    }

    public func remove(spring: ATSpring?) {
        //assert(spring != nil, "ATKernel.remove(spring:) - spring is nil")
        guard let validSpring = spring else { return }
        
        physicsQueue()?.async(execute: {
            self._physics.remove(spring: validSpring)
        });
    }

//MARK:  - Internal Interface

    private var _timer: DispatchSourceTimer?
    private var _queue : DispatchQueue?
    private var _isPaused: Bool = false
    private var _isRunning: Bool = false

    private func physicsQueue() -> DispatchQueue? {
        if (_queue == nil) {
            _queue = DispatchQueue(label: "com.prestonsoft.psarbortouch")
        }
        return _queue;
    }

    private struct Constant {
        struct TimeIntervalInMilliSeconds {
        static let Repeating = 50
        static let Leeway = 25
        }
    }
    
    private func physicsTimer() -> DispatchSourceTimer? {
        if _timer == nil {
            _timer = DispatchSource.makeTimerSource(queue: physicsQueue())
            _timer!.schedule(deadline: DispatchTime.now(),
                             repeating: DispatchTimeInterval.milliseconds(Constant.TimeIntervalInMilliSeconds.Repeating),
                             leeway: DispatchTimeInterval.milliseconds(Constant.TimeIntervalInMilliSeconds.Leeway))
        }
        
        return _timer
    }

}
