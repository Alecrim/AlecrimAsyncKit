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
    
    public static func didRegisterForRemoteNotificationsWithDeviceToken(deviceToken: NSData) {
        self.result = .Token(deviceToken)
        NSNotificationCenter.defaultCenter().postNotificationName(self.remoteNotificationPermissionName, object: nil, userInfo: ["token": deviceToken])
    }
    
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
                
                NSOperationQueue.mainQueue().addOperationWithBlock {
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
