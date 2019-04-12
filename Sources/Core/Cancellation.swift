//
//  Cancellation.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 10/03/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation

// MARK: -

public typealias CancellationHandler = () -> Void

// MARK: -

public final class Cancellation {
    private var _cancellationHandlerLock = os_unfair_lock_s()
    private var _cancellationHandler: CancellationHandler?

    internal init() {

    }
    
    fileprivate func addCancellationHandler(_ newValue: @escaping CancellationHandler) {
        os_unfair_lock_lock(&self._cancellationHandlerLock); defer { os_unfair_lock_unlock(&self._cancellationHandlerLock) }
        
        if let oldValue = self._cancellationHandler {
            self._cancellationHandler = {
                oldValue()
                newValue()
            }
        }
        else {
            self._cancellationHandler = newValue
        }
    }
    
    internal func run() {
        os_unfair_lock_lock(&self._cancellationHandlerLock); defer { os_unfair_lock_unlock(&self._cancellationHandlerLock) }

        //
        if let cancellationHandler = self._cancellationHandler {
            self._cancellationHandler = nil
            cancellationHandler()
        }
    }
}

public func +=(left: Cancellation, right: @escaping CancellationHandler) {
    left.addCancellationHandler(right)
}



