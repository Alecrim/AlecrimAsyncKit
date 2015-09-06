//
//  NetworkActivityTaskObserver.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-08-15.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

#if os(iOS)

private var _activitySpinLock = OS_SPINLOCK_INIT
private var _activity: Int = 0

/// A task observer that will cause the network activity indicator to appear as long as the observed task is executing.
public final class NetworkActivityTaskObserver: TaskObserver {
    
    private let delay: NSTimeInterval = 0.5
    private let application: UIApplication
    
    private var activity: Int {
        get {
            withUnsafeMutablePointer(&_activitySpinLock, OSSpinLockLock)
            let v = _activity
            withUnsafeMutablePointer(&_activitySpinLock, OSSpinLockUnlock)
            
            return v
        }
        set {
            withUnsafeMutablePointer(&_activitySpinLock, OSSpinLockLock)
            _activity = newValue
            withUnsafeMutablePointer(&_activitySpinLock, OSSpinLockUnlock)
            
            if self.activity > 0 {
                let when = dispatch_time(DISPATCH_TIME_NOW, Int64(self.delay * Double(NSEC_PER_SEC)))
                dispatch_after(when, dispatch_get_main_queue()) {
                    if self.activity > 0 {
                        self.application.networkActivityIndicatorVisible = true
                    }
                }
            }
            else {
                let when = dispatch_time(DISPATCH_TIME_NOW, Int64((self.delay / 2.0) * Double(NSEC_PER_SEC)))
                dispatch_after(when, dispatch_get_main_queue()) {
                    if self.activity == 0 {
                        self.application.networkActivityIndicatorVisible = false
                    }
                }
            }
        }
    }

    /// Initializes a task observer that will cause the network activity indicator to appear as long as the observed task is executing.
    ///
    /// - parameter application: The application where the network activity indicator belongs to.
    ///
    /// - returns: A task observer that will cause the network activity indicator to appear as long as the observed task is executing.
    ///
    /// - note: Usually you will pass `UIApplication.sharedApplication()` as parameter. This is needed because the framework is marked to allow app extension API only.
    public init(application: UIApplication) {
        self.application = application
        super.init()
        
        self.didStart { [unowned self] _ in
            self.activity++
        }
        
        self.didFinish { [unowned self] _ in
            self.activity--
        }
    }
    
}

#endif
