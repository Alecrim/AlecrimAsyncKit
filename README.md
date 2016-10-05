![AlecrimAsyncKit](https://raw.githubusercontent.com/Alecrim/AlecrimAsyncKit/master/AlecrimAsyncKit.png)

[![Language: Swift](https://img.shields.io/badge/lang-Swift 3-orange.svg?style=flat)](https://developer.apple.com/swift/)
[![Platform](https://img.shields.io/cocoapods/p/AlecrimAsyncKit.svg?style=flat)](http://cocoadocs.org/docsets/AlecrimAsyncKit)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](https://raw.githubusercontent.com/Alecrim/AlecrimAsyncKit/develop/LICENSE)
[![CocoaPods](https://img.shields.io/cocoapods/v/AlecrimAsyncKit.svg?style=flat)](http://cocoapods.org)
[![Apps](https://img.shields.io/cocoapods/at/AlecrimAsyncKit.svg?style=flat)](http://cocoadocs.org/docsets/AlecrimAsyncKit)
[![Twitter](https://img.shields.io/badge/twitter-@vmartinelli-blue.svg?style=flat)](https://twitter.com/vmartinelli)

Bringing async and await to Swift world with some flavouring.

## Using the framework

### The basics

As implemented in **AlecrimAsyncKit**, there are two types of tasks: failable and non-failable.

Both types can have a value associated to its completion. The first type, which is more safe and should be the most used in many cases, can also have an associated error.

Tasks can be “awaited” only in background, never on the main thread to not block the app and/or the user interface.

#### Failable tasks

A failable task is created passing a closure to the `async` global function (that returns a `Task<T>` instance that can be "awaited"). Inside the closure we must return the task value if it is not `Void`. We can also throw errors.

```swift
// this code is running in background
do {
    // the task is started immediately
    let task = asyncCalculate()

    // we can do other things while the calculation is made...
    // ...

    // now we need the value
    let value = try await(task)
    
    print("The result is \(value)")
}
catch let error {
    print(error)
}

func asyncCalculate() -> Task<Int> {
    return async {
        var value = 0

        for i in 0..<1_000_000 {
            value = i
        }

        if i >= 1_000_000 {
            // when using async with a failable task, we can throw errors
            throw AAKError.general
        }

        // when using async, we return the task value
        return value
    }
}
```

#### Non-failable tasks

A non-failable task is created passing a closure to the `async` global function too, but from the closure body it is only possible to return a value (if this value is not `Void`). It is not possible to throw errors in this task type therefore.

You mark a task as non-failable using `NonFailableTask<T>` class instead of `Task<T>`.


```swift
// this code is running in background
let value = await { asyncCalculate() }
print("The result is \(value)")

func asyncCalculate() -> NonFailableTask<Int> {
    return async {
        var value = 0

        for i in 0..<1_000_000 {
            value = i
        }

        // when using async, we return the task value
        return value
    }
}
```

### Advanced use

#### Async, extended

Sometimes a task can not be performed in a linear fashion or it depends on other pieces of code running in other threads. Sometimes a task will only be completed in another context or in another thread. In these cases you use the `asyncEx` global function instead of `async` to create a failable or non-failable task.

The three main differences in this case: a `task` parameter is used as parameter of the task closure body; a value cannot be returned using the `return` keyword; you will *must always* report the task completion using the appropriate `Task<T>`/`NonFailableTask<T>` methods (`finish`, `finishWithValue:`, `finishWithError:`, `finishWithValue:error:`).

```swift
import Foundation
import CloudKit

// Some code running in background.

let database: CKDatabase = ...

do {
    let records = try await(database.asyncPerform(query, inZoneWith: zoneID))

    for record in records {
        // ...
    }
}
catch let error {
    // do a nice error handling here
}


// A convenience `CKDatabase` extension.

extension CKDatabase {

    public func asyncPerform(_ query: CKQuery, inZoneWith zoneID: CKRecordZoneID?) -> Task<[CKRecord]> {
        return asyncEx { task in
            self.perform(query, inZoneWith: zoneID) { records, error in
                task.finish(with: records, or: error)
            }
        }
    }

}
```



A task completion can also be reported outside the task closure body. Examples of this can be seen in the iOS project example code.


#### Background queues

If other queue is not specified a task will run in a default (and shared) background queue. You can specify which queue the task will run using the optional parameter `queue` from `async` global function.

```swift
@warn_unused_result
func doSomething() -> Task<Void> {
    return async(in: queue) {
        // ...
    }
}
```

#### Conditions

One or many conditions (that can be either "satisfied", "not satisfied" or "failed") can be taken into account before a task is started.

A condition is an instance from the `TaskCondition` class that can be passed as parameter to the `async` global function when a task is created.

One task may have one or more conditions. Different tasks can have the same conditions if applicable to your logic. Also: static conditions and newly created ones are treated the same way, they are always evaluated each time a task that have them is to start.

The **AlecrimAsyncKit** framework provides some predefined conditions, but you can create others. The `MutuallyExclusiveCondition` is one special kind of condition that prevents tasks that share the same behavior from running at the same time.

```swift
func asyncDoSomething() -> Task<Void> {
    let condition = TaskCondition { result in
        if ... {
            result(.satisfied)
        }
        else {
            result(.failed(AAKError.general))
        }
    }

    return async(conditions: [condition]) {
        // ...
    }
}
```

If any of the task conditions is not satisfied the task will not be started. Only failable tasks can have conditions.


#### Observers

A task can have its beginning and its ending observed using the `TaskObserver` class instances. The observers can be passed to the `async` global function when a task is created.

The **AlecrimAsyncKit** framework provides some predefined observers, but you can create others.

```swift
func asyncDoSomething() -> Task<Void> {
    let observer = TaskObserver()
        .didStartTask { _ in
            print("The task was started...")
        }
        .didFinishTask { _ in
            print("The task was finished...")
        }

    return async(observers: [observer]) {
        // ...
    }
}
```

#### Task cancellation

Since a task is started when it is created it can only be cancelled after running (if you want to cancel a task before it starts, use conditions).

To cancel a task you use `asyncEx` method to create it and use the `cancel` method of `Task<T>` class.

To cancel a task is the same as finishing it with a `NSError` with `NSUserCancelledError` code.

If you want to use task cancellation you'll have check inside the task body closure for the `cancelled` property to stop any work the task are doing as soon it is cancelled.

Only failable tasks can be cancelled.

#### The main thread

Even if you cannot "await" a task on main thread, you still can start a background task from the main thread.

If you want to handle its completion you may use methods from `TaskAwaiter` helper class. If the queue parameter is not added, the callback closures will be called on the main thread.

```swift
// this code is running on the main thread

let _ = asyncCalculate()
    .didFinishWithValue { value in
        print("The result is \(value)")
    }
    .didFinishWithError { error in
        // do a nice error handling here
    }
    .didCancel {
        print("Task was cancelled")
    }
    .didFinish { task in
        // this closure will be always called, even if the task was cancelled

        if let error = error where !error.isUserCancelled {
            // do a nice error handling here
        }
        else {
            print("The result is \(value)")
        }
    }

func asyncCalculate() -> Task<Int> {
    return async {
        var value = 0

        for i in 0..<1_000_000 {
            value = i
        }

        if i >= 1_000_000 {
            // when using async with a failable task, we can throw errors
            throw ...
        }

        // when using async, we return the task value
        return value
    }
}
```

The difference between a failable task and a non-failable task is that a non-failable task waiter is called `NonFailableTaskAwaiter` and it does not have the `didFinishWithError` and `didCancel` methods.

### Considerations

After its creation the task is immediately started in background. Its completion can be "awaited" using the `await` global function, that blocks the current thread until the task finishes. When finished the task return value is available and the next line after the `await` call is performed normally.

If a task is not "awaited" it will be performed anyway. In this case no code in any thread will be blocked and its returning value will be discarded.

Multiple `await` calls for the same task are possible. In this case the task will run only once, but when it is finished the value will be available to all `await` calls.

A specific task instance only lives once and cannot be "reused", so when it is finished, it must be released (ARC in most cases will do it for you). More than one instance of the same task can be performed in parallel, however (if you return a task from a `func`, for example).

In the task closure body it is possible to "await" other tasks too.

## Motivation
To make things simpler and get rid of the “completionHandler pyramid of doom”. I must confess that one thing that I’d like to see in Swift is a better asynchronous task management than the `completionHandler:` way. Even that version 2 has brought several important and extremely well implemented features, this in particular was missing.

The `async` and `await` was first implemented in **AlecrimFoundation** framework (a private **Alecrim** framework) with a few lines of code wrote in Swift 1.x. Then they were ported to their own framework and the source was opened as the features have evolved.

## Inspiration
The `async`/`await` concept from .NET platform. Yes, I am a very happy OS X/iOS developer but the world is not and should not be limited to this and there are very good things there that we can bring to this side.

The Session 226 of WWDC 2015 (“Advanced NSOperations”) that exemplified several interesting concepts using operations (but missed a simple way to pass data between them).

## Branches and contribution

- master - The production branch. Clone or fork this repository for the latest copy.
- develop - The active development branch. [Pull requests](https://help.github.com/articles/creating-a-pull-request) should be directed to this branch.

---

## Contact
- [Vanderlei Martinelli](https://github.com/vmartinelli)

## License
**AlecrimAsyncKit** is released under an MIT license. See LICENSE for more information.
