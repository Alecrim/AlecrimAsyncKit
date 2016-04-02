//
//  NetworkActivityIndicatorTaskObserver.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-08-15.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

#if os(iOS)
    import UIKit
#endif

// MARK: - Handler Protocol

public protocol NetworkActivityIndicatorHandlerType: class {
    var networkActivityIndicatorVisible: Bool { get set }
}

// MARK: - Observer

public final class NetworkActivityIndicatorTaskObserver: TaskDidStartObserverType, TaskDidFinishObserverType {

    // MARK: - Public Properties
    
    public var showDelay: NSTimeInterval = 2.0
    public var dismissDelay: NSTimeInterval = 0.25
    
    // MARK: - Private Properties

    private var activityCountSpinLock = OS_SPINLOCK_INIT
    private var activityCount: Int = 0
    
    private unowned let networkActivityIndicatorHandler: NetworkActivityIndicatorHandlerType
    
    // MARK: - Observer Protocols Conformance
    
    public func didStart(task: TaskType) {
        self.increment()
    }
    
    public func didFinish(task: TaskType) {
        self.decrement()
    }
    
    // MARK: - Initializer
    
    public init(handler networkActivityIndicatorHandler: NetworkActivityIndicatorHandlerType) {
        assert(!networkActivityIndicatorHandler.networkActivityIsAssigned, "There can be only one NetworkActivityIndicatorTaskObserver associated to a NetworkActivityIndicatorHandlerType instance.")

        self.networkActivityIndicatorHandler = networkActivityIndicatorHandler
        self.networkActivityIndicatorHandler.networkActivity = self
    }
    
    // MARK: - Public Methods
    
    public func increment() {
        do {
            withUnsafeMutablePointer(&self.activityCountSpinLock, OSSpinLockLock)
            defer { withUnsafeMutablePointer(&self.activityCountSpinLock, OSSpinLockUnlock) }
            
            self.activityCount += 1
        }
        
        self.showOrHideActivityIndicatorAfterDelay()
    }
    
    public func decrement() {
        do {
            withUnsafeMutablePointer(&self.activityCountSpinLock, OSSpinLockLock)
            defer { withUnsafeMutablePointer(&self.activityCountSpinLock, OSSpinLockUnlock) }
            
            self.activityCount -= 1
            
            #if DEBUG
                if self.activityCount < 0 {
                    print("Something is wrong. The activity count is \(self.activityCount).")
                }
            #endif
        }
        
        self.showOrHideActivityIndicatorAfterDelay()
    }
    
    // MARK: - Private Methods
    
    private func showOrHideActivityIndicatorAfterDelay() {
        dispatch_async(dispatch_get_main_queue()) {
            let delay = (self.networkActivityIndicatorHandler.networkActivityIndicatorVisible ? self.dismissDelay : self.showDelay)
            let when = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
            
            dispatch_after(when, dispatch_get_main_queue()) {
                withUnsafeMutablePointer(&self.activityCountSpinLock, OSSpinLockLock)
                defer { withUnsafeMutablePointer(&self.activityCountSpinLock, OSSpinLockUnlock) }
                
                let visible = (self.activityCount > 0)
                if visible && !self.networkActivityIndicatorHandler.networkActivityIndicatorVisible {
                    self.networkActivityIndicatorHandler.networkActivityIndicatorVisible = true
                }
                else if !visible && self.networkActivityIndicatorHandler.networkActivityIndicatorVisible {
                    self.networkActivityIndicatorHandler.networkActivityIndicatorVisible = false
                }
            }
        }
    }
    
}

// MARK: - Convenience Operators

public postfix func ++(networkActivityIndicatorTaskObserver: NetworkActivityIndicatorTaskObserver) {
    networkActivityIndicatorTaskObserver.increment()
}

public postfix func --(networkActivityIndicatorTaskObserver: NetworkActivityIndicatorTaskObserver) {
    networkActivityIndicatorTaskObserver.decrement()
}

// MARK: - Associated Properties

private struct AssociatedKeys {
    private static var networkActivity = "networkActivity"
}

extension NetworkActivityIndicatorHandlerType {
    
    public private(set) var networkActivity: NetworkActivityIndicatorTaskObserver {
        get {
            if let value = objc_getAssociatedObject(self, &AssociatedKeys.networkActivity) as? NetworkActivityIndicatorTaskObserver {
                return value
            }
            else {
                return NetworkActivityIndicatorTaskObserver(handler: self) // associated object will be assigned inside the initializer
            }
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.networkActivity, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    private var networkActivityIsAssigned: Bool {
        if let _ = objc_getAssociatedObject(self, &AssociatedKeys.networkActivity) as? NetworkActivityIndicatorTaskObserver {
            return true
        }
        else {
            return false
        }
    }
    
}


// MARK: - UIApplication Extension

#if os(iOS)
    
    extension UIApplication: NetworkActivityIndicatorHandlerType {
    
    }
    
#endif
