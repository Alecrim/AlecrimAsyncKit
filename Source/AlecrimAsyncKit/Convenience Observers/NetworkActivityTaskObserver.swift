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

    public static var delay: NSTimeInterval = 0.5

    private static var activitySpinLock = OS_SPINLOCK_INIT
    private static var _activity: Int = 0

    private let application: UIApplication
    
    private func showOrHideActivityIndicatorAfterDelay() {
        let when = dispatch_time(DISPATCH_TIME_NOW, Int64(NetworkActivityTaskObserver.delay * Double(NSEC_PER_SEC)))
        dispatch_after(when, dispatch_get_main_queue()) {
            withUnsafeMutablePointer(&NetworkActivityTaskObserver.activitySpinLock, OSSpinLockLock)
            self.application.networkActivityIndicatorVisible = (NetworkActivityTaskObserver._activity > 0)
            withUnsafeMutablePointer(&NetworkActivityTaskObserver.activitySpinLock, OSSpinLockUnlock)
        }
    }
    
    /// Initializes a task observer that will cause the network activity indicator to appear as long as the observed task is executing.
    ///
    /// - parameter application: The application where the network activity indicator belongs to.
    ///
    /// - returns: A task observer that will cause the network activity indicator to appear as long as the observed task is executing.
    ///
    /// - note: Usually you will pass `UIApplication.sharedApplication()` as parameter. This is needed because the framework is marked to allow app extension API only.
    private init(application: UIApplication) {
        self.application = application
        super.init()
        
        self.didStart { [unowned self] _ in
            self.incrementActivity()
        }
        
        self.didFinish { [unowned self] _ in
            self.decrementActivity()
        }
    }
    
    public func incrementActivity() {
        withUnsafeMutablePointer(&NetworkActivityTaskObserver.activitySpinLock, OSSpinLockLock)
        NetworkActivityTaskObserver._activity++
        withUnsafeMutablePointer(&NetworkActivityTaskObserver.activitySpinLock, OSSpinLockUnlock)
        
        self.showOrHideActivityIndicatorAfterDelay()
    }
    
    public func decrementActivity() {
        withUnsafeMutablePointer(&NetworkActivityTaskObserver.activitySpinLock, OSSpinLockLock)
        NetworkActivityTaskObserver._activity--
        
        //assert(NetworkActivityTaskObserver._activity >= 0)
        if NetworkActivityTaskObserver._activity < 0 {
            print("Something is wrong -> activity:", NetworkActivityTaskObserver._activity)
            NetworkActivityTaskObserver._activity = 0
        }
        
        withUnsafeMutablePointer(&NetworkActivityTaskObserver.activitySpinLock, OSSpinLockUnlock)
        
        self.showOrHideActivityIndicatorAfterDelay()
    }
    
}
    
extension UIApplication {

    private struct AssociatedKeys {
        private static var networkActivityTaskObserver = "com.alecrim.AlecrimAsyncKit.UIApplication.NetworkActivityTaskObserver"
    }
    
    public var networkActivityTaskObserver: NetworkActivityTaskObserver {
        get {
            if let value = objc_getAssociatedObject(self, &AssociatedKeys.networkActivityTaskObserver) as? NetworkActivityTaskObserver {
                return value
            }
            else {
                let newValue = NetworkActivityTaskObserver(application: self)
                objc_setAssociatedObject(self, &AssociatedKeys.networkActivityTaskObserver, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                
                return newValue
            }
        }
    }

}

#endif
