//
//  Errors.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-09-05.
//  Copyright © 2015 Alecrim. All rights reserved.
//

import Foundation

// MARK: -

/// The possible errors related to task condition evaluation.
///
/// - notSatisfied: The condition was not satisfied.
/// - failed:       The condition evaluation was failed with an error.
public enum TaskConditionError: Error {
    case notSatisfied
    case failed(Error)
}

// MARK: -

/// Predefined domain for errors from AlecrimAsyncKit.
public let AlecrimAsyncKitErrorDomain = "com.alecrim.AlecrimAsyncKit.ErrorDomain"

// MARK: -

extension NSError {
    
    /// Creates an `NSError` that represents an user cancelled error.
    ///
    /// - parameter domain: The error domain—this can be one of the predefined NSError domains, or an arbitrary string describing a custom domain.
    /// - parameter dict:   The `userInfo` dictionary for the error. `userInfo` is optional and may be `nil`.
    ///
    /// - returns: An `NSError` object for domain that represents an user cancelled error and the dictionary of arbitrary data userInfo.
    public static func userCancelledError(domain: String, userInfo dict: [String : Any]? = nil) -> NSError {
        return NSError(domain: domain, code: NSUserCancelledError, userInfo: dict)
    }
    
}

// MARK: -

extension Error {
    
    /// A Boolean value indicating whether the receiver represents an user cancelled error.
    public var isUserCancelled: Bool {
        return (self as NSError).code == NSUserCancelledError
    }
    
}
