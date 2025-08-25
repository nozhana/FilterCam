//
//  MotionService.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/22/25.
//

import CoreMotion
import Foundation
import OSLog

final actor MotionService {
    private let manager = CMMotionManager()
    private let activityManager = CMMotionActivityManager()
    
    private let attitudeSubject = AsyncSubject.of(CMAttitude.self)
    private let activitySubject = AsyncSubject.of(CMMotionActivity.self)
    private let motionQueue = OperationQueue()
    
    static let shared = MotionService()
    
    private init() {}
    
    var attitudes: AsyncStream<CMAttitude> {
        attitudeSubject.stream
    }
    
    var activities: AsyncStream<CMMotionActivity> {
        activitySubject.stream
    }
    
    deinit {
        manager.stopDeviceMotionUpdates()
        activityManager.stopActivityUpdates()
    }
    
    func startUpdates() {
        startManager()
        // startActivityManager()
    }
    
    func stopUpdates() {
        manager.stopDeviceMotionUpdates()
        // activityManager.stopActivityUpdates()
    }
    
    private func startManager() {
        manager.deviceMotionUpdateInterval = 0.01
        manager.startDeviceMotionUpdates(using: .xTrueNorthZVertical, to: motionQueue) { [weak self] motion, error in
            if let error {
                Logger.motion.error("Failed to start device motion updates: \(error)")
                return
            }
            
            if let self, let motion {
                attitudeSubject.send(motion.attitude)
            }
        }
    }
    
    private func startActivityManager() {
        activityManager.startActivityUpdates(to: motionQueue) { [weak self] activity in
            if let self, let activity {
                activitySubject.send(activity)
            }
        }
    }
}

extension Logger {
    static let motion = Logger(subsystem: "com.nozhana.FilterCam.logging", category: "motion")
}
