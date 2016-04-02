//
//  TaskObserver.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2015-08-04.
//  Copyright © 2015 Alecrim. All rights reserved.
//

import Foundation

// MARK: -

public protocol TaskObserverType {
}

public protocol TaskWillStartObserverType: TaskObserverType {
    func willStart(task: TaskType)
}

public protocol TaskDidStartObserverType: TaskObserverType {
    func didStart(task: TaskType)
}

public protocol TaskWillFinishObserverType: TaskObserverType {
    func willFinish(task: TaskType)
}

public protocol TaskDidFinishObserverType: TaskObserverType {
    func didFinish(task: TaskType)
}
