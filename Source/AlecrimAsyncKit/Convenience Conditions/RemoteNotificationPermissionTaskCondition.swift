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


/// A condition for verifying that the app has the ability to receive push notifications.
public final class RemoteNotificationPermissionTaskCondition: TaskCondition {
    
    private enum RemoteRegistrationStatus {
        case Unknown
        case Success
        case Error(ErrorType)
    }


    private static var statusObserverClosure: ((RemoteNotificationPermissionTaskCondition.RemoteRegistrationStatus) -> Void)? = nil
    private static var status = RemoteNotificationPermissionTaskCondition.RemoteRegistrationStatus.Unknown
    
    // MARK: -

    /// This method has to be called inside the `UIApplicationDelegate` response to the registration success.
    ///
    /// - parameter deviceToken: The received device token.
    public static func didRegisterForRemoteNotifications(deviceToken deviceToken: NSData) {
        self.statusObserverClosure?(.Success)
    }
    
    /// This method has to be called inside the `UIApplicationDelegate` response to the registration error.
    ///
    /// - parameter error: The received error.
    public static func didFailToRegisterForRemoteNotifications(error error: NSError) {
        self.statusObserverClosure?(.Error(error))
    }
    
    // MARK: -
    
    private static func asyncWaitForResponse(application application: UIApplication) -> Task<Void> {
        return asyncEx { task in
            if application.isRegisteredForRemoteNotifications() {
                self.status = .Success
                task.finish()
            }
            else {
                self.statusObserverClosure = { result in
                    self.statusObserverClosure = nil
                    
                    switch result {
                    case .Success:
                        self.status = .Success
                        task.finish()
                        
                    case .Error(let error):
                        self.status = .Error(error)
                        task.finishWith(error: error)
                        
                    default:
                        fatalError("Invalid result: \(result).")
                    }
                }
                
                application.registerForRemoteNotifications()
            }
        }
    }
    
    private static var dependencyTask: Task<Void>?
    
    // MARK: -

    /// Initializes a condition for verifying that the app has the ability to receive push notifications.
    ///
    /// - parameter application: The application instance.
    ///
    /// - returns: A condition for verifying that the app has the ability to receive push notifications.
    ///
    /// - note: Usually you will pass `UIApplication.sharedApplication()` as parameter. This is needed because the framework is marked to allow app extension API only.
    private init(application: UIApplication) {
        let dependencyTask: Task<Void>
        if let staticDependencyTask = self.dynamicType.dependencyTask {
            dependencyTask = staticDependencyTask
        }
        else {
            dependencyTask = RemoteNotificationPermissionTaskCondition.asyncWaitForResponse(application: application)
            self.dynamicType.dependencyTask = dependencyTask
        }
        
        super.init(dependencyTask: dependencyTask) { result in
            switch RemoteNotificationPermissionTaskCondition.status {
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
            objc_setAssociatedObject(self, &AssociatedKeys.remoteNotificationPermissionTaskCondition, value, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            return value
        }
    }
    
}

#endif
