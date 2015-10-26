//
//  NetworkActivityIndicatorTaskObserver.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-08-15.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

#if os(iOS)

// MARK: -
    
    
private var _activitySpinLock = OS_SPINLOCK_INIT
private var _activity: Int = 0

    
public final class NetworkActivityIndicatorTaskObserver<T: TaskType, V where T.ValueType == V>: TaskObserver<T, V> {

    public var delay: NSTimeInterval = 0.5

    private let application: UIApplication
    
    public init(application: UIApplication) {
        self.application = application
        super.init()
        
        self.taskDidStart { _ in
            self.incrementActivity()
        }
        
        self.taskDidFinish { _ in
            self.decrementActivity()
        }
    }
    
    private func showOrHideActivityIndicatorAfterDelay() {
        let when = dispatch_time(DISPATCH_TIME_NOW, Int64(self.delay * Double(NSEC_PER_SEC)))
        dispatch_after(when, dispatch_get_main_queue()) {
            withUnsafeMutablePointer(&_activitySpinLock, OSSpinLockLock)
            self.application.networkActivityIndicatorVisible = (_activity > 0)
            withUnsafeMutablePointer(&_activitySpinLock, OSSpinLockUnlock)
        }
    }
    
    
    public func incrementActivity() {
        withUnsafeMutablePointer(&_activitySpinLock, OSSpinLockLock)
        _activity++
        withUnsafeMutablePointer(&_activitySpinLock, OSSpinLockUnlock)
        
        self.showOrHideActivityIndicatorAfterDelay()
    }
    
    public func decrementActivity() {
        withUnsafeMutablePointer(&_activitySpinLock, OSSpinLockLock)
        _activity--
        
        if _activity < 0 {
            print("Something is wrong -> activity count:", _activity)
        }
        
        withUnsafeMutablePointer(&_activitySpinLock, OSSpinLockUnlock)
        
        self.showOrHideActivityIndicatorAfterDelay()
    }
    
}
    
postfix public func ++<T, V>(nai: NetworkActivityIndicatorTaskObserver<T, V>) {
    nai.incrementActivity()
}

postfix public func --<T, V>(nai: NetworkActivityIndicatorTaskObserver<T, V>) {
    nai.decrementActivity()
}


#endif
