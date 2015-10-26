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
        
        private static var activitySpinLock = OS_SPINLOCK_INIT
        private static var activity: Int = 0

        public static var delay: NSTimeInterval = 0.5
        
        private let application: UIApplication
        
        private init(application: UIApplication) {
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
            let when = dispatch_time(DISPATCH_TIME_NOW, Int64(self.dynamicType.delay * Double(NSEC_PER_SEC)))
            dispatch_after(when, dispatch_get_main_queue()) {
                withUnsafeMutablePointer(&self.dynamicType.activitySpinLock, OSSpinLockLock)
                self.application.networkActivityIndicatorVisible = (self.dynamicType.activity > 0)
                withUnsafeMutablePointer(&self.dynamicType.activitySpinLock, OSSpinLockUnlock)
            }
        }
        
        
        public func incrementActivity() {
            withUnsafeMutablePointer(&self.dynamicType.activitySpinLock, OSSpinLockLock)
            self.dynamicType.activity++
            withUnsafeMutablePointer(&self.dynamicType.activitySpinLock, OSSpinLockUnlock)
            
            self.showOrHideActivityIndicatorAfterDelay()
        }
        
        public func decrementActivity() {
            withUnsafeMutablePointer(&self.dynamicType.activitySpinLock, OSSpinLockLock)
            self.dynamicType.activity--
            
            if self.dynamicType.activity < 0 {
                print("Something is wrong -> activity count:", self.dynamicType.activity)
            }
            
            withUnsafeMutablePointer(&self.dynamicType.activitySpinLock, OSSpinLockUnlock)
            
            self.showOrHideActivityIndicatorAfterDelay()
        }
        
    }
    
    // MARK: -
    
    postfix public func ++(nai: NetworkActivityIndicatorTaskObserver) {
        nai.incrementActivity()
    }
    
    postfix public func --(nai: NetworkActivityIndicatorTaskObserver) {
        nai.decrementActivity()
    }
    
    // MARK: -
    
    extension UIApplication {

        public func networkActivityIndicatorTaskObserver() -> NetworkActivityIndicatorTaskObserver {
            return NetworkActivityIndicatorTaskObserver(application: self)
        }
        
    }
    
    
#endif
