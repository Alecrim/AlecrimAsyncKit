//
//  Cancellation.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 10/03/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation

// MARK: -

private let _cancellationDispatchQueue = DispatchQueue(label: "com.alecrim.AlecrimAsyncKit.Cancellation", qos: .utility, attributes: .concurrent, target: DispatchQueue.global(qos: .utility))

// MARK: -

public typealias CancellationHandler = () -> Void

// MARK: -

public final class Cancellation {
    private var _cancellationHandlersLock = os_unfair_lock_s()
    private var _cancellationHandlers: [CancellationHandler]?

    internal init() {

    }
    
    fileprivate func addCancellationHandler(_ newValue: @escaping CancellationHandler) {
        os_unfair_lock_lock(&self._cancellationHandlersLock); defer { os_unfair_lock_unlock(&self._cancellationHandlersLock) }

        if self._cancellationHandlers == nil {
            self._cancellationHandlers = [newValue]
        }
        else {
            self._cancellationHandlers!.append(newValue)
        }
    }
    
    internal func run() {
        var cancellationHandlers: [CancellationHandler]?

        do {
            os_unfair_lock_lock(&self._cancellationHandlersLock); defer { os_unfair_lock_unlock(&self._cancellationHandlersLock) }
            cancellationHandlers = self._cancellationHandlers
            self._cancellationHandlers = nil
        }

        //
        cancellationHandlers?.forEach {
            $0()
        }
    }

    internal func run(after workItem: DispatchWorkItem) {
        workItem.notify(queue: _cancellationDispatchQueue, execute: self.run)
    }
}

// MARK: -

public func +=(left: Cancellation, right: @escaping CancellationHandler) {
    left.addCancellationHandler(right)
}



