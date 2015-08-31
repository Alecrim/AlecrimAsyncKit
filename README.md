# AlecrimAsyncKit
Bringing async and await to Swift world with some flavouring.

## Getting Started

More docs will be here soon, but you will be able to write something like this:

```swift
let task = asyncDoSomethingNonFailableInBackground()
    
// do other things while task is running
for o in 0..<1_000_000 {
    //
}
    
// now we need the task result value
let value = await(task)
print(value)

// in the Swift world it is better to have "async" as a prefix (not a suffix)
// for the task returning `func` name
func asyncDoSomethingNonFailableInBackground() -> NonFailableTask<Int> {
    return async {
        var value = 0
    
        for i in 0..<1_000_000_000 {
           value = i
        }
        
        return value
    }
}

```

Or:

```swift
do {
    let value = try await { asyncDoSomethingInBackground() }
    print(value)
}
catch let error {
    print(error)
}

// in the Swift world it is better to have "async" as a prefix (not a suffix)
// for the task returning `func` name
func asyncDoSomethingInBackground() -> Task<Int> {
    return async {
        var error: ErrorType? = nil
        var value = 0
        
        for i in 0..<1_000_000_000 {
           value = i
        }
        
        // ...
        
        if let error = error {
            throw error
        }

        retur value
    }
}

```

---

## Contact

- [Vanderlei Martinelli](https://github.com/vmartinelli)

## License

AlecrimAsyncKit is released under an MIT license. See LICENSE for more information.
