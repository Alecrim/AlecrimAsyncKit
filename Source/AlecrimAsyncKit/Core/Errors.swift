//
//  Errors.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-09-05.
//  Copyright © 2015 Alecrim. All rights reserved.
//

import Foundation

// MARK: -

/// The possible errors related to task condition evalution.
///
/// - NotSatisfied: The condition was not satisfied.
/// - Failed:       The condition evaluation was failed with an error.
public enum TaskConditionError: ErrorType {
    case notSatisfied
    case failed(ErrorType)
}

// MARK: -

extension NSError {
    
    /// Creates an `NSError` that represents an user cancelled error.
    ///
    /// - parameter domain: The error domain—this can be one of the predefined NSError domains, or an arbitrary string describing a custom domain.
    /// - parameter dict:   The `userInfo` dictionary for the error. `userInfo` is optional and may be `nil`.
    ///
    /// - returns: An `NSError` object for domain that represents an user cancelled error and the dictionary of arbitrary data userInfo.
    public static func userCancelledError(domain domain: String = NSCocoaErrorDomain, userInfo dict: [NSObject : AnyObject]? = nil) -> NSError {
        return NSError(domain: domain, code: NSUserCancelledError, userInfo: dict)
    }
    
}

extension ErrorType {
    
    /// A Boolean value indicating whether the receiver represents an user cancelled error.
    public var isUserCancelled: Bool {
        return (self as NSError).code == NSUserCancelledError
    }
    
}
