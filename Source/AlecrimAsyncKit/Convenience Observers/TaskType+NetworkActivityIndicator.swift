//
//  TaskType+NetworkActivityIndicator.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-08-15.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

#if os(iOS)

// MARK: -
    
public final class NetworkActivityIndicatorCounter {

    public static var delay: NSTimeInterval = 0.5

    private static var activitySpinLock = OS_SPINLOCK_INIT
    private static var _activity: Int = 0

    private let application: UIApplication
    
    private init(application: UIApplication) {
        self.application = application
    }
    
    private func showOrHideActivityIndicatorAfterDelay() {
        let when = dispatch_time(DISPATCH_TIME_NOW, Int64(self.dynamicType.delay * Double(NSEC_PER_SEC)))
        dispatch_after(when, dispatch_get_main_queue()) {
            withUnsafeMutablePointer(&self.dynamicType.activitySpinLock, OSSpinLockLock)
            self.application.networkActivityIndicatorVisible = (self.dynamicType._activity > 0)
            withUnsafeMutablePointer(&self.dynamicType.activitySpinLock, OSSpinLockUnlock)
        }
    }
    
    
    public func incrementActivity() {
        withUnsafeMutablePointer(&self.dynamicType.activitySpinLock, OSSpinLockLock)
        self.dynamicType._activity++
        withUnsafeMutablePointer(&self.dynamicType.activitySpinLock, OSSpinLockUnlock)
        
        self.showOrHideActivityIndicatorAfterDelay()
    }
    
    public func decrementActivity() {
        withUnsafeMutablePointer(&self.dynamicType.activitySpinLock, OSSpinLockLock)
        self.dynamicType._activity--
        
        //assert(NetworkActivityTaskObserver._activity >= 0)
        if self.dynamicType._activity < 0 {
            print("Something is wrong -> activity:", self.dynamicType._activity)
            self.dynamicType._activity = 0
        }
        
        withUnsafeMutablePointer(&self.dynamicType.activitySpinLock, OSSpinLockUnlock)
        
        self.showOrHideActivityIndicatorAfterDelay()
    }
    
}
    
postfix public func ++(nai: NetworkActivityIndicatorCounter) {
    nai.incrementActivity()
}

postfix public func --(nai: NetworkActivityIndicatorCounter) {
    nai.decrementActivity()
}

    
// MARK: -
    
extension UIApplication {

    private struct AssociatedKeys {
        private static var networkActivityCount = "com.alecrim.AlecrimAsyncKit.UIApplication.networkActivityCount"
    }
    
    public var networkActivityCount: NetworkActivityIndicatorCounter {
        get {
            if let value = objc_getAssociatedObject(self, &AssociatedKeys.networkActivityCount) as? NetworkActivityIndicatorCounter {
                return value
            }
            else {
                let newValue = NetworkActivityIndicatorCounter(application: self)
                objc_setAssociatedObject(self, &AssociatedKeys.networkActivityCount, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                
                return newValue
            }
        }
    }

}
    
// MARK: -
    
extension TaskType {
    
    public func bindToNetworkActivityIndicatorFromApplication(application: UIApplication) -> Self {
        self.didStart { _ in
            application.networkActivityCount.incrementActivity()
        }
        
        self.didFinish { _ in
            application.networkActivityCount.decrementActivity()
        }
        
        return self
    }
    
}

#endif
