//
//  Availability.swift
//  AlecrimAsyncKit
//
//  Created by Vanderlei Martinelli on 2016-05-21.
//  Copyright © 2016 Alecrim. All rights reserved.
//

import Foundation

// MARK: - Core Conditions

@available(*, unavailable, renamed: "MutuallyExclusiveCondition")
public final class MutuallyExclusiveTaskCondition {}

// MARK: - Additional Conditions

@available(*, unavailable, renamed: "BooleanCondition")
public final class BooleanTaskCondition {}

@available(*, unavailable, renamed: "DelayCondition")
public final class DelayTaskCondition {}

@available(*, unavailable, renamed: "NegateCondition")
public final class NegateTaskCondition {}

@available(*, unavailable, renamed: "ObjectValueCondition")
public final class ObjectValueTaskCondition {}

@available(*, unavailable, renamed: "SilentCondition")
public final class SilentTaskCondition {}

// MARK: - Convenience Conditions

@available(*, unavailable, renamed: "EventStorePermissionCondition")
public final class EventStorePermissionTaskCondition {}

@available(*, unavailable, renamed: "LocationPermissionCondition")
public final class LocationPermissionTaskCondition {}

@available(*, unavailable, renamed: "PhotosPermissionCondition")
public final class PhotosPermissionTaskCondition {}

@available(*, unavailable, renamed: "ReachabilityCondition")
public final class ReachabilityTaskCondition {}

@available(*, unavailable, renamed: "RemoteNotificationPermissionCondition")
public final class RemoteNotificationPermissionTaskCondition {}

// MARK: - Additional Observers

@available(*, unavailable, renamed: "TimeoutObserver")
public final class TimeoutTaskObserver {}

// MARK: - Convenience Observers

@available(*, unavailable, renamed: "ApplicationBackgroundObserver")
public final class ApplicationBackgroundTaskObserver {}

@available(*, unavailable, renamed: "NetworkActivityIndicatorObserver")
public final class NetworkActivityIndicatorTaskObserver {}

@available(*, unavailable, renamed: "ProcessInfoActivityObserver")
public final class ProcessInfoActivityTaskObserver {}

// MARK: -

#if os(iOS)
    
    extension UIApplication {
        
        @available(*, unavailable, renamed: "applicationBackgroundObserver")
        public final func applicationBackgroundTaskObserver() -> ApplicationBackgroundObserver {
            fatalError()
        }
        
        @available(*, unavailable, renamed: "networkActivity")
        public final func networkActivityIndicatorTaskObserver() -> NetworkActivityIndicatorObserver {
            fatalError()
        }
        
    }
    
#endif


// MARK: -

extension Task {
    
    @available(*, unavailable, renamed: "finish")
    public final func finishWithValue(value: V) {
        fatalError()
    }

    @available(*, unavailable, renamed: "finish")
    public final func finishWithError(error: Error) {
        fatalError()
    }

    @available(*, unavailable, renamed: "finish")
    public final func finishWithValue(value: V!, error: Error?) {
        fatalError()
    }
    
}

extension NonFailableTask {

    @available(*, unavailable, renamed: "finish")
    public final func finishWithValue(value: V) {
        fatalError()
    }

}

// MARK: -

extension FailableTaskProtocol {

    @available(*, unavailable, renamed: "forward")
    public func `continue`<T: FailableTaskProtocol where T.ValueType == Self.ValueType>(with task: T, inheritCancellation: Bool = true) {
        fatalError()
    }
    
    @available(*, unavailable, renamed: "forward")
    public func continueWith<T: FailableTaskProtocol where T.ValueType == Self.ValueType>(task: T, inheritCancellation: Bool = true) {
        fatalError()
    }

}

extension NonFailableTaskProtocol {
    
    @available(*, unavailable, renamed: "forward")
    public func `continue`<T: NonFailableTaskProtocol where T.ValueType == Self.ValueType>(with task: T) {
        fatalError()
    }

    @available(*, unavailable, renamed: "forward")
    public func continueWith<T: NonFailableTaskProtocol where T.ValueType == Self.ValueType>(task: T) {
        fatalError()
    }

}

