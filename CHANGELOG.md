# AlecrimAsyncKit

## 5.0
- New architecture;
- Swift 5.0 compatible.

## 4.0
- New architecture.

## 3.1
- Converted to Swift 4.0.

## 3.0.1
- Bug fixes and improvements.

## 3.0
- Swift 3 compatible version.

## 2.2.1
- Swift 2.3 compatibility.

## 2.2
- Last Swift 2.2 compatible version.

## 2.1.1
- Fixed a bug where mutually exclusive condition semaphore is not signed when the operation is cancelled before its start.

## 2.1
- Renamed `TaskWaiter` to `TaskAwaiter`;
- Simplified main thread awaiting.

## 2.0.2
- Added tvOS as target.

## 2.0.1
- Fix to cancellation before task was started.

## 2.0
- New architecture for tasks and queues;
- Added `TaskWaiter`;
- Other improvements and fixes.

## 1.2.3
- Changed OS X deployment target to version 10.10.

## 1.2.2
- `NetworkActivityTaskObserver` fixes.

## 1.2.1
- Some platform compatibility fixes.

## 1.2
- Added some documentation;
- Added more convenience conditions and observers;
- Other minor changes.

## 1.1.3
- Better condition dependency task handling (now the dependency task only starts when condition is evaluated);
- Other minor changes.

## 1.1.2
- Fixed condition evaluation when a task is created (but not awaited) on main thread.

## 1.0
- Initial version.
