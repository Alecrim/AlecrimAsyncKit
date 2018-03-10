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
I know I am puttting the cart before the horse, but... For the three functions in the next section you can await the returning value in the same way:

```swift
func someFuncRunningInBackground() throws {
    let value = try await { someLongRunningAsynchronousFunc() }
    
    // do something with the returned value...
}
```

You can also use the result only when needed:

```swift
func someFuncRunningInBackground() throws {
    // the task starts immediately
    let task = someLongRunningAsynchronousFunc()
    
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

### Cancellation
You can cancel a task after it was enqueued using its `cancel()` method. When it will be actually cancelled depends on the implementation of its content, however.

Cancelling a task in **AlecrimAsyncKit** is pretty the same as finishig it with an `NSError` with `NSCocoaErrorDomain` and `NSUserCancelledError` as parameters. But if you use `cancel()` cancellation actions can be fired using provided blocks.

You can add cancellation blocks to be executed when a task is cancelled this way:

```swift
func someLongRunningAsynchronousFunc -> Task<SomeValuableValue> {
    return async { thisAsyncTask in
        let token = self.getSomeValuableValue(completionHandler: { value, error in
            task.finish(with: value, or: error)
        })
        
        // add a block to be executed when and if the task is cancelled
        thisAsyncTask.cancellation += {
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
    // start the task from the main thread
    someLongRunningAsynchronousFunc().didFinishWithValue { value in
        // when the background work is done,
        // do something with the returned value (in the main thread again)
    }
}
```

## Non failable tasks
If you read the framework's code you will find the `NonFailableTask<Value>` class. This kind of task cannot fail (sort of). In fact it may fail, but it should not.

The main difference from the failable task class is that you do not have to use the `try` keyword when awaiting for non failable task results. A non failable task cannot be cancelled either.

Please only use this type of task when you are sure that it can not fail.

## Observers and conditions
The previous version had observers and conditions based on Session 226 of WWDC 2015 (“Advanced NSOperations”). This turned the framework unnecessarily complex.

If you need this functionality right now you can use version 3.x of **AlecrimAsyncKit**.

Observers and conditions may be implemented in a future release or as a separated framework. No guarantees, though.

## Contribute
If you have any problems or need more information, please open an issue using the provided GitHub link.

You can also contribute by fixing errors or creating new features. When doing this, please submit your pull requests to this repository as I do not have much time to "hunt" forks for not submited patches.

- master - The production branch. Clone or fork this repository for the latest copy.
- develop - The active development branch. [Pull requests](https://help.github.com/articles/creating-a-pull-request) should be directed to this branch.


## Contact the author
- [Vanderlei Martinelli](https://www.linkedin.com/in/vmartinelli)

## License
**AlecrimAsyncKit** is released under an MIT license. See LICENSE for more information.
