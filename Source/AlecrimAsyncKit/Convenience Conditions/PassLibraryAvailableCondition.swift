//
//  PassLibraryAvailableCondition.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-09-05.
//  Copyright © 2015 Alecrim. All rights reserved.
//

#if os(iOS)

import Foundation
import PassKit

/// A condition for verifying that Passbook exists and is accessible.
public final class PassLibraryAvailableCondition: TaskCondition {
    
    /// Initializes a condition for verifying that Passbook exists and is accessible.
    ///
    /// - returns: A condition for verifying that Passbook exists and is accessible.
    public init() {
        super.init() { result in
            if PKPassLibrary.isPassLibraryAvailable() {
                result(.Satisfied)
            }
            else {
                result(.NotSatisfied)
            }
        }
    }
    
}

#endif
