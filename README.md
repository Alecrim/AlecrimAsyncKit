# AlecrimAsyncKit
Bringing async and await to Swift world with some flavouring.

## Getting Started

Docs will be here soon, but you will be able to write something like this:

```swift
let task = asyncDoSomethingNonFailableInBackground()
    
// do other things while task is running
for o in 0..<1_000_000 {
    //
}
    
// now we need the task result
let result = await(task)
print(result)

// in the Swift world it is better to have "async" as a prefix (not a suffix)
// for the task returning `func` name
func asyncDoSomethingNonFailableInBackground() -> NonFailableTask<Int> {
    return async { task in
        var result = 0
    
        for i in 0..<1_000_000_000 {
           result = i
        }
        
        task.finishWithValue(result)
    }
}

```

Or:

```swift
do {
    let result = try await { asyncDoSomethingInBackground() }
    print(result)
}
catch let error {
    print(error)
}

// in the Swift world it is better to have "async" as a prefix (not a suffix)
// for the task returning `func` name
func asyncDoSomethingInBackground() -> Task<Int> {
    return async { task in
        var error: ErrorType? = nil
        var result = 0
        
        for i in 0..<1_000_000_000 {
           result = i
        }
        
        // ...
        
        if let error = error {
            task.finishWithError(error)
        }
        else {
            task.finishWithValue(result)
        }
    }
}

```

---

## Contact

- [Vanderlei Martinelli](https://github.com/vmartinelli)

## License

AlecrimAsyncKit is released under an MIT license. See LICENSE for more information.
