//
//  PhotosPermissionTaskCondition.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-09-05.
//  Copyright © 2015 Alecrim. All rights reserved.
//

#if os(iOS)

import Foundation
import Photos

/// A condition for verifying access to the user's Photos library.
public final class PhotosPermissionTaskCondition: TaskCondition {
    
    private static func asyncRequestAuthorizationIfNeeded() -> Task<Void> {
        return asyncEx(condition: MutuallyExclusiveTaskCondition(.Alert)) { task in
            let authorizationStatus = PHPhotoLibrary.authorizationStatus()
            
            if case .NotDetermined = authorizationStatus {
                NSOperationQueue.mainQueue().addOperationWithBlock {
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

    public init() {
        super.init(dependencyTask: PhotosPermissionTaskCondition.asyncRequestAuthorizationIfNeeded()) { result in
            let authorizationStatus = PHPhotoLibrary.authorizationStatus()
            
            if case .Authorized = authorizationStatus {
                result(.Satisfied)
            }
            else {
                result(.NotSatisfied)
            }
        }
    }
    
}

#endif
