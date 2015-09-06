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
    case Token(NSData)
    case Error(ErrorType)
}

/// A condition for verifying that the app has the ability to receive push notifications.
public final class RemoteNotificationPermissionTaskCondition: TaskCondition {

    private static let remoteNotificationPermissionName = "com.alecrim.AlecrimAsyncKit.RemoteNotificationPermissionNotification"
    private static var result = RemoteRegistrationResult.Unknown
    
    /// This method has to be called inside the `UIApplicationDelegate` response to the registration success.
    ///
    /// - parameter deviceToken: The received device token.
    public static func didRegisterForRemoteNotificationsWithDeviceToken(deviceToken: NSData) {
        self.result = .Token(deviceToken)
        NSNotificationCenter.defaultCenter().postNotificationName(self.remoteNotificationPermissionName, object: nil, userInfo: ["token": deviceToken])
    }
    
    /// This method has to be called inside the `UIApplicationDelegate` response to the registration error.
    ///
    /// - parameter error: The received error.
    public static func didFailToRegisterForRemoteNotificationsWithError(error: NSError) {
        self.result = .Error(error)
        NSNotificationCenter.defaultCenter().postNotificationName(self.remoteNotificationPermissionName, object: nil, userInfo: ["error": error])
    }
    
    private static func asyncWaitResponseFromApplication(application: UIApplication) -> Task<Void> {
        return asyncEx(condition: MutuallyExclusiveTaskCondition(.Alert)) { task in
            switch self.result {
            case .Unknown:
                self.result = .Waiting
                
                var observer: AnyObject!
                observer = NSNotificationCenter().addObserverForName(RemoteNotificationPermissionTaskCondition.remoteNotificationPermissionName, object: nil, queue: nil) { notification in
                    NSNotificationCenter.defaultCenter().removeObserver(observer)
                    observer = nil
                    
                    if let userInfo = notification.userInfo {
                        if let _ = userInfo["token"] as? NSData {
                            task.finish()
                        }
                        else if let error = userInfo["error"] as? NSError {
                            task.finishWithError(error)
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
                
            case .Token:
                task.finish()
                
            case .Error(let error):
                task.finishWithError(error)
                
            default:
                break
            }
        }
    }

    /// Initializes a condition for verifying that the app has the ability to receive push notifications.
    ///
    /// - parameter application: The application instance.
    ///
    /// - returns: A condition for verifying that the app has the ability to receive push notifications.
    ///
    /// - note: Usually you will pass `UIApplication.sharedApplication()` as parameter. This is needed because the framework is marked to allow app extension API only.
    public init(application: UIApplication) {
        super.init(dependencyTask: RemoteNotificationPermissionTaskCondition.asyncWaitResponseFromApplication(application)) { result in
            switch RemoteNotificationPermissionTaskCondition.result {
            case .Token:
                result(.Satisfied)
                
            case .Error(let error):
                result(.Failed(error))
                
            default:
                result(.NotSatisfied)
            }
        }
    }
    
}

#endif
