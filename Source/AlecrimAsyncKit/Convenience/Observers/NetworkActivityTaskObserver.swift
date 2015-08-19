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

public final class NetworkActivityTaskObserver<V>: TaskObserver<V> {
    
    private let delay: NSTimeInterval = 1.0
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
                let when = dispatch_time(DISPATCH_TIME_NOW, Int64(self.delay * Double(NSEC_PER_SEC)))
                dispatch_after(when, dispatch_get_main_queue()) {
                    if self.activity <= 0 {
                        self.application.networkActivityIndicatorVisible = false
                    }
                }
            }
        }
    }

    
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
