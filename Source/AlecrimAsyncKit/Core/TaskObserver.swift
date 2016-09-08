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
    func willStartTask(_ task: TaskProtocol)
}

public protocol TaskDidStartObserver: TaskObserver {
    func didStartTask(_ task: TaskProtocol)
}

public protocol TaskWillFinishObserver: TaskObserver {
    func willFinishTask(_ task: TaskProtocol)
}

public protocol TaskDidFinishObserver: TaskObserver {
    func didFinishTask(_ task: TaskProtocol)
}
