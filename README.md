![AlecrimAsyncKit](https://raw.githubusercontent.com/Alecrim/AlecrimAsyncKit/master/AlecrimAsyncKit.png)

[![Language: Swift](https://img.shields.io/badge/Swift-4.0-orange.svg?style=flat)](https://developer.apple.com/swift/)
[![Platforms](https://img.shields.io/cocoapods/p/AlecrimAsyncKit.svg?style=flat)](http://cocoadocs.org/docsets/AlecrimAsyncKit)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](https://raw.githubusercontent.com/Alecrim/AlecrimAsyncKit/develop/LICENSE)
[![CocoaPods](https://img.shields.io/cocoapods/v/AlecrimAsyncKit.svg?style=flat)](http://cocoapods.org)
[![Apps](https://img.shields.io/cocoapods/at/AlecrimAsyncKit.svg?style=flat)](http://cocoadocs.org/docsets/AlecrimAsyncKit)
[![Author: vmartinelli](https://img.shields.io/badge/author-vmartinelli-blue.svg?style=flat)](https://www.linkedin.com/in/vmartinelli)

async and await for Swift.

## Usage
### Awaiting the results
Maybe I am putting the cart before the horses, but... For all the functions in the next section you can await the returning value in the same way:

```swift
func someFuncRunningInBackground() throws {
    let value = try await { self.someLongRunningAsynchronousFunc() }

    // do something with the returned value...
}
```

You can also use the result only when needed:

```swift
func someFuncRunningInBackground() throws {
    // the task starts immediately
    let task = self.someLongRunningAsynchronousFunc()

    // do other things, the task is running...

    // continue doing other things...
    // the task can be still running or maybe it is already finished, who knows?

    //
    let value = try await(task)

    // do something with the returned value...
}
```

### Creating an asynchronous task
You can simply return the desired value inside the `async` closure.

```swift
func someLongRunningAsynchronousFunc -> Task<SomeValuableValue> {
    return async {
        let value = self.createSomeValuableValue()

        // some long running code here...

        return value
    }    
}
```

If you are calling a method with completion handler, however, you may need a different closure signature with the task itself as parameter and call its `finish(with:)` method when the work is finished.

```swift
func someLongRunningAsynchronousFunc -> Task<SomeValuableValue> {
    return async { task in
        self.getSomeValuableValue(completionHandler: { value in
            task.finish(with: value)
        })        
    }    
}
```
If the completion handler has an error as additional parameter, you can pass it to the `finish` method too (and it will be handled in the `try` statement when awaiting for the task result).

```swift
func someLongRunningAsynchronousFunc -> Task<SomeValuableValue> {
    return async { task in
        self.getSomeValuableValue(completionHandler: { value, error in
            task.finish(with: value, or: error)
        })        
    }    
}
```

### Creating tasks using DispatchQueue and OperationQueue
You can also create tasks using convenience methods added to `DispatchQueue` and `OperationQueue`:

```swift
func calculate() -> Double {
    // using DispatchQueue
    let someCalculatedValue = await(DispatchQueue.global(qos: .background).async {
        var value: Double = 0

        // do some long running calculation here

        return value
    } as NonFailableTask<Double>)

    // using OperationQueue
    let operationQueue = OperationQueue()
    operationQueue.qualityOfService = .background

    let operationTask = operationQueue.addOperation {
        var value: Double = 0

        // do some long running calculation here

        return value
    } as NonFailableTask<Double>


    // using the results
    return someCalculatedValue * await(operationTask)
}
```

### Cancellation
You can cancel a task after it was enqueued using its `cancel()` method. When it will be actually cancelled depends on the implementation of its content, however.

Cancelling a task in **AlecrimAsyncKit** is pretty the same as finishing it with an `NSError` with `NSCocoaErrorDomain` and `NSUserCancelledError` as parameters. But if you use `cancel()` cancellation actions can be fired using provided blocks.

You can add cancellation blocks to be executed when a task is cancelled this way:

```swift
func someLongRunningAsynchronousFunc -> Task<SomeValuableValue> {
    return async { task in
        let token = self.getSomeValuableValue(completionHandler: { value, error in
            task.finish(with: value, or: error)
        })

        // add a closure to be executed when and if the task is cancelled
        task.cancellation += {
           token.invalidate()
        }        
    }    
}
```

Of course this can be done only if you are using the "extended" async closure signature as you will may need the `task` parameter.

The framework will try to "inherit" cancellation for child tasks when possible. This means that if a parent task is cancelled, the tasks that started within its implementation may be also cancelled without major interventions.


### The main thread

Since the `await` func blocks the current thread, you can only await an async func on a background `DispatchQueue`, `OperationQueue` or `Thread`. However you can do the following in the main thread:

```swift
func someFuncRunningInTheMainThread() {
    //
    self.activityIndicator.startAnimating()

    // start the background task
    self.someLongRunningAsynchronousFunc()
        .then { value in
            // when the background work is done,
            // do something with the returned value in the main thread
        }
        .catch { error in
            // do a nice error handling
        }
        .finally {
            self.activityIndicator.stopAnimating()
    }
}
```

All methods (`then`, `catch`, `cancelled` and `finally`) are optional. When specified, the closure related to the `finally` method will always be called regardless whether the task was cancelled or not, whether there was an error or not.

## Non failable tasks
If you read the framework's code you will find the `NonFailableTask<Value>` class. This kind of task cannot fail (sort of). In fact it may fail, but it should not.

The main difference from the failable task class is that you do not have to `try` when awaiting for non failable task results. A non failable task cannot be cancelled either.

Please only use this type of task when you are sure that it cannot fail. If it do and the task fail your program will crash.

## Dependencies, conditions and observers
The previous version had observers and conditions based on Session 226 of WWDC 2015 (“Advanced NSOperations”). This turned the framework unnecessarily complex. If you need this functionality right now you can use version 3.x of **AlecrimAsyncKit**.

In version 4.0 the framework has the notion of "dependencies" and a new kind of "conditions" was implemented. Observers may reappear in a future release. No guarantees, though.

## Contribute
If you have any problems or need more information, please open an issue using the provided GitHub link.

You can also contribute by fixing errors or creating new features. When doing this, please submit your pull requests to this repository as I do not have much time to "hunt" forks for not submitted patches.

- master - The production branch. Clone or fork this repository for the latest copy.
- develop - The active development branch. [Pull requests](https://help.github.com/articles/creating-a-pull-request) should be directed to this branch.


## Contact the author
- [Vanderlei Martinelli](https://www.linkedin.com/in/vmartinelli)

## License
**AlecrimAsyncKit** is released under an MIT license. See LICENSE for more information.
