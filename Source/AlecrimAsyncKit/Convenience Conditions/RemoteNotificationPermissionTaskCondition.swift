//
//  RemoteNotificationPermissionTaskCondition.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-08-05.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

#if os(iOS)

import Foundation
import UIKit

private enum RemoteRegistrationResult {
    case Unknown
    case Waiting
    case Success
    case Error(ErrorType)
}

/// A condition for verifying that the app has the ability to receive push notifications.
public final class RemoteNotificationPermissionTaskCondition: TaskCondition {

    private static let remoteNotificationPermissionName = "com.alecrim.AlecrimAsyncKit.RemoteNotificationPermissionNotification"
    private static var result = RemoteRegistrationResult.Unknown
    
    // MARK: -

    /// This method has to be called inside the `UIApplicationDelegate` response to the registration success.
    ///
    /// - parameter deviceToken: The received device token.
    public static func didRegisterForRemoteNotifications(deviceToken deviceToken: NSData) {
        self.result = .Success
        NSNotificationCenter.defaultCenter().postNotificationName(self.remoteNotificationPermissionName, object: nil, userInfo: ["token": deviceToken])
    }
    
    /// This method has to be called inside the `UIApplicationDelegate` response to the registration error.
    ///
    /// - parameter error: The received error.
    public static func didFailToRegisterForRemoteNotifications(error error: NSError) {
        self.result = .Error(error)
        NSNotificationCenter.defaultCenter().postNotificationName(self.remoteNotificationPermissionName, object: nil, userInfo: ["error": error])
    }
    
    // MARK: -
    
    private static var observer: AnyObject? {
        didSet {
            if let oldValue = oldValue {
                NSNotificationCenter.defaultCenter().removeObserver(oldValue)
            }
        }
    }
    
    private static func asyncWaitForResponse(application application: UIApplication) -> Task<Void> {
        return asyncEx(conditions: [MutuallyExclusiveTaskCondition(category: .Alert)]) { task in
            if application.isRegisteredForRemoteNotifications() {
                self.result = .Success
            }
            
            switch self.result {
            case .Unknown:
                self.result = .Waiting
                
                self.observer = NSNotificationCenter().addObserverForName(RemoteNotificationPermissionTaskCondition.remoteNotificationPermissionName, object: nil, queue: nil) { notification in
                    self.observer = nil
                    
                    if let userInfo = notification.userInfo {
                        if let _ = userInfo["token"] as? NSData {
                            task.finish()
                        }
                        else if let error = userInfo["error"] as? NSError {
                            task.finishWith(error: error)
                        }
                        else {
                            fatalError("Received a notification without a token and without an error.")
                        }
                    }
                    else {
                        fatalError("userInfo is nil.")
                    }
                }
                
                dispatch_async(dispatch_get_main_queue()) {
                    application.registerForRemoteNotifications()
                }
                
            case .Success:
                task.finish()
                
            case .Error(let error):
                task.finishWith(error: error)
                
            default:
                break
            }
        }
    }
    
    // MARK: -

    /// Initializes a condition for verifying that the app has the ability to receive push notifications.
    ///
    /// - parameter application: The application instance.
    ///
    /// - returns: A condition for verifying that the app has the ability to receive push notifications.
    ///
    /// - note: Usually you will pass `UIApplication.sharedApplication()` as parameter. This is needed because the framework is marked to allow app extension API only.
    private init(application: UIApplication) {
        super.init(dependencyTask: RemoteNotificationPermissionTaskCondition.asyncWaitForResponse(application: application)) { result in
            switch RemoteNotificationPermissionTaskCondition.result {
            case .Success:
                result(.Satisfied)
                
            case .Error(let error):
                result(.Failed(error))
                
            default:
                result(.NotSatisfied)
            }
        }
    }
    
}
    
// MARK: - UIApplication extension


extension UIApplication {
    
    private struct AssociatedKeys {
        private static var remoteNotificationPermissionTaskCondition = "remoteNotificationPermissionTaskCondition"
    }
    
    public var remoteNotificationPermissionTaskCondition: RemoteNotificationPermissionTaskCondition {
        if let value = objc_getAssociatedObject(self, &AssociatedKeys.remoteNotificationPermissionTaskCondition) as? RemoteNotificationPermissionTaskCondition {
            return value
        }
        else {
            let value = RemoteNotificationPermissionTaskCondition(application: self)
            objc_setAssociatedObject(self, &AssociatedKeys.remoteNotificationPermissionTaskCondition, value, .OBJC_ASSOCIATION_RETAIN_NONATOMIC )
            
            return value
        }
    }
    
}

#endif
