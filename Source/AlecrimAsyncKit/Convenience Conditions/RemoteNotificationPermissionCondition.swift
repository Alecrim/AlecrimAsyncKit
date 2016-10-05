//
//  RemoteNotificationPermissionCondition.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-08-05.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

#if os(OSX) || os(iOS)
    
    import Foundation
    
#if os(OSX)
    
    import AppKit
    
    public typealias RemoteNotificationPermissionConditionApplication = NSApplication
    
#endif
    
#if os(iOS)
    
    import UIKit
    
    public typealias RemoteNotificationPermissionConditionApplication = UIApplication
    
#endif

    private enum RemoteRegistrationStatus {
        case unknown
        case success
        case error(Error)
    }
    
    /// A condition for verifying that the app has the ability to receive push notifications.
    public final class RemoteNotificationPermissionCondition: TaskCondition {
        
        private static var statusObserverClosure: ((RemoteRegistrationStatus) -> Void)? = nil
        private static var status = RemoteRegistrationStatus.unknown
        
        #if os(OSX)
        public static var remoteNotificationTypes: NSRemoteNotificationType = []
        #endif
        
        // MARK: -
        
        /// This method has to be called inside the `UIApplicationDelegate` response to the registration success.
        ///
        /// - parameter deviceToken: The received device token.
        public static func didRegisterForRemoteNotifications(with deviceToken: NSData) {
            self.statusObserverClosure?(.success)
        }
        
        /// This method has to be called inside the `UIApplicationDelegate` response to the registration error.
        ///
        /// - parameter error: The received error.
        public static func didFailToRegisterForRemoteNotifications(with error: NSError) {
            self.statusObserverClosure?(.error(error))
        }
        
        // MARK: -
        
        private static func waitForResponse(from application: RemoteNotificationPermissionConditionApplication) -> Task<Void> {
            return asyncEx { task in
                if application.isRegisteredForRemoteNotifications {
                    self.status = .success
                    task.finish()
                }
                else {
                    self.statusObserverClosure = { result in
                        self.statusObserverClosure = nil
                        
                        switch result {
                        case .success:
                            self.status = .success
                            task.finish()
                            
                        case .error(let error):
                            self.status = .error(error)
                            task.finish(with: error)
                            
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
        fileprivate init(application: RemoteNotificationPermissionConditionApplication) {
            let dependencyTask: Task<Void>
            if let staticDependencyTask = type(of: self).dependencyTask {
                dependencyTask = staticDependencyTask
            }
            else {
                dependencyTask = RemoteNotificationPermissionCondition.waitForResponse(from: application)
                type(of: self).dependencyTask = dependencyTask
            }
            
            super.init(dependencyTask: dependencyTask) { result in
                switch RemoteNotificationPermissionCondition.status {
                case .success:
                    result(.satisfied)
                    
                case .error(let error):
                    result(.failed(error))
                    
                default:
                    result(.notSatisfied)
                }
            }
        }
        
    }
    
    // MARK: - UIApplication extension
    
    
    extension RemoteNotificationPermissionConditionApplication {
        
        private struct AssociatedKeys {
            fileprivate static var remoteNotificationPermissionCondition = "remoteNotificationPermissionCondition"
            
            #if os(OSX)
            fileprivate static var registeredForRemoteNotifications = "registeredForRemoteNotifications"
            #endif
            
        }
        
        public var remoteNotificationPermissionCondition: RemoteNotificationPermissionCondition {
            if let value = objc_getAssociatedObject(self, &AssociatedKeys.remoteNotificationPermissionCondition) as? RemoteNotificationPermissionCondition {
                return value
            }
            else {
                let value = RemoteNotificationPermissionCondition(application: self)
                objc_setAssociatedObject(self, &AssociatedKeys.remoteNotificationPermissionCondition, value, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                
                return value
            }
        }
        
        #if os(OSX)
        
        private var __registeredForRemoteNotifications: Bool {
            get {
                if let number = objc_getAssociatedObject(self, &AssociatedKeys.registeredForRemoteNotifications) as? NSNumber {
                    return number.boolValue
                }
                
                return false
            }
            set {
                let number = NSNumber(value: newValue)
                objc_setAssociatedObject(self, &AssociatedKeys.registeredForRemoteNotifications, number, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
        
        fileprivate func registerForRemoteNotifications() {
            self.registerForRemoteNotifications(matching: RemoteNotificationPermissionCondition.remoteNotificationTypes)
            self.__registeredForRemoteNotifications = true
        }
        
        fileprivate var isRegisteredForRemoteNotifications: Bool {
            return self.__registeredForRemoteNotifications
        }

        #endif
        
    }
    
#endif
