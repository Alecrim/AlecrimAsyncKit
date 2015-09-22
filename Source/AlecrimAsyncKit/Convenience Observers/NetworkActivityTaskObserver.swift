//
//  NetworkActivityTaskObserver.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-08-15.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

#if os(iOS)

/// A task observer that will cause the network activity indicator to appear as long as the observed task is executing.
public final class NetworkActivityTaskObserver: TaskObserver {

    private static var _activitySpinLock = OS_SPINLOCK_INIT
    private static var _activity: Int = 0

    private let delay: NSTimeInterval = 0.5
    private let application: UIApplication
    
    private func incrementActivity() {
        withUnsafeMutablePointer(&NetworkActivityTaskObserver._activitySpinLock, OSSpinLockLock)
        NetworkActivityTaskObserver._activity++
        withUnsafeMutablePointer(&NetworkActivityTaskObserver._activitySpinLock, OSSpinLockUnlock)
        
        self.showOrHideActivityIndicatorAfterDelay()
    }
    
    private func decrementActivity() {
        withUnsafeMutablePointer(&NetworkActivityTaskObserver._activitySpinLock, OSSpinLockLock)
        NetworkActivityTaskObserver._activity--
        withUnsafeMutablePointer(&NetworkActivityTaskObserver._activitySpinLock, OSSpinLockUnlock)
        
        self.showOrHideActivityIndicatorAfterDelay()
    }
    
    private func showOrHideActivityIndicatorAfterDelay() {
        let when = dispatch_time(DISPATCH_TIME_NOW, Int64(self.delay * Double(NSEC_PER_SEC)))
        dispatch_after(when, dispatch_get_main_queue()) {
            withUnsafeMutablePointer(&NetworkActivityTaskObserver._activitySpinLock, OSSpinLockLock)
            
            let value = NetworkActivityTaskObserver._activity
            
            if value > 0 {
                self.application.networkActivityIndicatorVisible = true
            }
            else {
                self.application.networkActivityIndicatorVisible = false
            }

            withUnsafeMutablePointer(&NetworkActivityTaskObserver._activitySpinLock, OSSpinLockUnlock)

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
            self.incrementActivity()
        }
        
        self.didFinish { [unowned self] _ in
            self.decrementActivity()
        }
    }
    
}

#endif
