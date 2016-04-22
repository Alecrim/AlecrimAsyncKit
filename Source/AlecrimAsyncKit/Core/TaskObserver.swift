//
//  TaskObserver.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-08-04.
//  Copyright © 2015 Alecrim. All rights reserved.
//

import Foundation

// MARK: -

public protocol TaskObserver {
}

public protocol TaskWillStartObserver: TaskObserver {
    func willStart(task: TaskProtocol)
}

public protocol TaskDidStartObserver: TaskObserver {
    func didStart(task: TaskProtocol)
}

public protocol TaskWillFinishObserver: TaskObserver {
    func willFinish(task: TaskProtocol)
}

public protocol TaskDidFinishObserver: TaskObserver {
    func didFinish(task: TaskProtocol)
}
