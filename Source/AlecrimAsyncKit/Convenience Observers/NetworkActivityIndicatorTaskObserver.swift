//
//  NetworkActivityIndicatorTaskObserver.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-08-15.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

#if os(iOS)
    
    public final class NetworkActivityIndicatorTaskObserver: TaskObserver {
        
        private static var _activitySpinLock = OS_SPINLOCK_INIT
        private static var _activity: Int = 0
        
        public static var showDelay: NSTimeInterval = 2.0
        public static var dismissDelay: NSTimeInterval = 0.25
        
        private unowned let application: UIApplication
        
        private init(application: UIApplication) {
            self.application = application
            super.init()
            
            self
                .taskDidStart { _ in
                    self.increment()
                }
                .taskDidFinish { _ in
                    self.decrement()
            }
        }
        
        public func increment() {
            do {
                withUnsafeMutablePointer(&self.dynamicType._activitySpinLock, OSSpinLockLock)
                defer { withUnsafeMutablePointer(&self.dynamicType._activitySpinLock, OSSpinLockUnlock) }
                
                self.dynamicType._activity += 1
            }
            
            self.showOrHideActivityIndicatorAfterDelay()
        }
        
        public func decrement() {
            do {
                withUnsafeMutablePointer(&self.dynamicType._activitySpinLock, OSSpinLockLock)
                defer { withUnsafeMutablePointer(&self.dynamicType._activitySpinLock, OSSpinLockUnlock) }

                self.dynamicType._activity -= 1

                #if DEBUG
                if self.dynamicType._activity < 0 {
                    print("Something is wrong -> activity count:", self.dynamicType._activity)
                }
                #endif
            }
            
            self.showOrHideActivityIndicatorAfterDelay()
        }
        
        private func showOrHideActivityIndicatorAfterDelay() {
            dispatch_async(dispatch_get_main_queue()) {
                let delay = (self.application.networkActivityIndicatorVisible ? self.dynamicType.dismissDelay : self.dynamicType.showDelay)
                let when = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
                
                dispatch_after(when, dispatch_get_main_queue()) {
                    withUnsafeMutablePointer(&self.dynamicType._activitySpinLock, OSSpinLockLock)
                    defer { withUnsafeMutablePointer(&self.dynamicType._activitySpinLock, OSSpinLockUnlock) }
                    
                    let visible = (self.dynamicType._activity > 0)
                    if visible && !self.application.networkActivityIndicatorVisible {
                        self.application.networkActivityIndicatorVisible = true
                    }
                    else if !visible && self.application.networkActivityIndicatorVisible {
                        self.application.networkActivityIndicatorVisible = false
                    }
                }
            }
        }
        
    }
    
    // MARK: -
    
    extension UIApplication {

        private struct AssociatedKeys {
            private static var networkActivity = "networkActivity"
        }
        
        public var networkActivity: NetworkActivityIndicatorTaskObserver {
            if let value = objc_getAssociatedObject(self, &AssociatedKeys.networkActivity) as? NetworkActivityIndicatorTaskObserver {
                return value
            }
            else {
                let value = NetworkActivityIndicatorTaskObserver(application: self)
                objc_setAssociatedObject(self, &AssociatedKeys.networkActivity, value, .OBJC_ASSOCIATION_RETAIN_NONATOMIC )
                
                return value
            }
        }
        
    }
    
    
#endif
