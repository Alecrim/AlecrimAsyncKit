//
//  NetworkActivityIndicatorObserver.swift
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

public protocol NetworkActivityIndicatorHandler: class {
    var isNetworkActivityIndicatorVisible: Bool { get set }
}

// MARK: - Observer

public final class NetworkActivityIndicatorObserver: TaskDidStartObserver, TaskDidFinishObserver {

    // MARK: - Public Properties
    
    public var showDelay: TimeInterval = 2.0
    public var dismissDelay: TimeInterval = 0.25
    
    // MARK: - Private Properties

    private var activityCountSpinLock = OS_SPINLOCK_INIT
    private var activityCount: Int = 0
    
    private unowned let networkActivityIndicatorHandler: NetworkActivityIndicatorHandler
    
    // MARK: - Observer Protocols Conformance
    
    public func didStartTask(_ task: TaskProtocol) {
        self.increment()
    }
    
    public func didFinishTask(_ task: TaskProtocol) {
        self.decrement()
    }
    
    // MARK: - Initializer
    
    public init(handler networkActivityIndicatorHandler: NetworkActivityIndicatorHandler) {
        assert(!networkActivityIndicatorHandler.networkActivityIsAssigned, "There can be only one NetworkActivityIndicatorTaskObserver associated to a NetworkActivityIndicatorHandlerType instance.")

        self.networkActivityIndicatorHandler = networkActivityIndicatorHandler
        self.networkActivityIndicatorHandler.networkActivity = self
    }
    
    // MARK: - Public Methods
    
    public func increment() {
        do {
            withUnsafeMutablePointer(to: &self.activityCountSpinLock, OSSpinLockLock)
            defer { withUnsafeMutablePointer(to: &self.activityCountSpinLock, OSSpinLockUnlock) }
            
            self.activityCount += 1
        }
        
        self.showOrHideActivityIndicatorAfterDelay()
    }
    
    public func decrement() {
        do {
            withUnsafeMutablePointer(to: &self.activityCountSpinLock, OSSpinLockLock)
            defer { withUnsafeMutablePointer(to: &self.activityCountSpinLock, OSSpinLockUnlock) }
            
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
        Queue.mainQueue.async() {
            let delay = self.networkActivityIndicatorHandler.isNetworkActivityIndicatorVisible ? self.dismissDelay : self.showDelay
            
            Queue.mainQueue.asyncAfter(deadline: DispatchTime.now() + delay) {
                withUnsafeMutablePointer(to: &self.activityCountSpinLock, OSSpinLockLock)
                defer { withUnsafeMutablePointer(to: &self.activityCountSpinLock, OSSpinLockUnlock) }
                
                let visible = (self.activityCount > 0)
                if visible && !self.networkActivityIndicatorHandler.isNetworkActivityIndicatorVisible {
                    self.networkActivityIndicatorHandler.isNetworkActivityIndicatorVisible = true
                }
                else if !visible && self.networkActivityIndicatorHandler.isNetworkActivityIndicatorVisible {
                    self.networkActivityIndicatorHandler.isNetworkActivityIndicatorVisible = false
                }
            }
        }
    }
    
}

// MARK: - Convenience Operators

public postfix func ++ (networkActivityObserver: NetworkActivityIndicatorObserver) {
    networkActivityObserver.increment()
}

public postfix func -- (networkActivityObserver: NetworkActivityIndicatorObserver) {
    networkActivityObserver.decrement()
}

// MARK: - Associated Properties

private struct AssociatedKeys {
    fileprivate static var networkActivity = "networkActivity"
}

extension NetworkActivityIndicatorHandler {
    
    public fileprivate(set) var networkActivity: NetworkActivityIndicatorObserver {
        get {
            if let value = objc_getAssociatedObject(self, &AssociatedKeys.networkActivity) as? NetworkActivityIndicatorObserver {
                return value
            }
            else {
                return NetworkActivityIndicatorObserver(handler: self) // associated object will be assigned inside the initializer
            }
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.networkActivity, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    fileprivate var networkActivityIsAssigned: Bool {
        if let _ = objc_getAssociatedObject(self, &AssociatedKeys.networkActivity) as? NetworkActivityIndicatorObserver {
            return true
        }
        else {
            return false
        }
    }
    
}


// MARK: - UIApplication Extension

#if os(iOS)
    
    extension UIApplication: NetworkActivityIndicatorHandler {
    
    }
    
#endif
