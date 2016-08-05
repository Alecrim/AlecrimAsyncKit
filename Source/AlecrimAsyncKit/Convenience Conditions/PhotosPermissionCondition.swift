//
//  PhotosPermissionCondition.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-09-05.
//  Copyright © 2015 Alecrim. All rights reserved.
//

#if os(iOS)

import Foundation
import Photos

/// A condition for verifying access to the user's Photos library.
public final class PhotosPermissionCondition: TaskCondition {
    
    private static func requestAuthorizationIfNeeded() -> Task<Void> {
        return asyncEx(conditions: [MutuallyExclusiveAlertCondition]) { task in
            let authorizationStatus = PHPhotoLibrary.authorizationStatus()
            
            if case .notDetermined = authorizationStatus {
                Queue.mainQueue.async {
                    PHPhotoLibrary.requestAuthorization { _ in
                        task.finish()
                    }
                }
            }
            else {
                task.finish()
            }
        }
    }

    /// Initializes a condition for verifying access to the user's Photos library.
    ///
    /// - returns: A condition for verifying access to the user's Photos library.
    public init() {
        super.init(dependencyTask: PhotosPermissionCondition.requestAuthorizationIfNeeded()) { result in
            let authorizationStatus = PHPhotoLibrary.authorizationStatus()
            
            if case .authorized = authorizationStatus {
                result(.satisfied)
            }
            else {
                result(.notSatisfied)
            }
        }
    }
    
}

#endif
