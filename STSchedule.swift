//
//  STSchedule.swift
//
//
//  Created by soso on 2017/4/21.
//
//

import UIKit

// Public
extension STSchedule {
    
    public func removeAll() {
        self.queue.async {
            self.timer.fireDate = Date.distantFuture
            self.values.removeAll()
        }
    }
    
    public func remove(forKey key: AnyHashable) {
        self.queue.async {
            self.values.removeValue(forKey: key)
            if self.values.count == 0 {
                self.timer.fireDate = Date.distantFuture
            }
        }
    }
    
    public func add(interval: Int = 1, repeat count: Int = Int.max, forKey key: AnyHashable, callbackQueue: DispatchQueue = .main, _ callback: @escaping (_ current: Int) -> Void) {
        self.queue.async {
            self.values[key] = Value(interval: interval, count: count, queue: callbackQueue, handle: callback)
            if self.timer.isValid {
                self.timer.fireDate = Date()
            }
        }
    }
}

// Private
extension STSchedule {
    
    @objc
    private func timerScheduled() {
        self.queue.async {
            var removeKeys = [AnyHashable]()
            self.values.forEach {
                if $0.value.count < 1 {
                    removeKeys.append($0.key)
                } else {
                    $0.value.fire()
                }
            }
            removeKeys.forEach {
                self.values.removeValue(forKey: $0)
                if self.values.count == 0 {
                    self.timer.fireDate = Date.distantFuture
                }
            }
        }
    }
}

public final class STSchedule {
    
    private class Value {
        
        var interval: Int
        var count: Int
        var queue: DispatchQueue
        var handle: (Int) -> Void
        
        init(interval: Int, count: Int, queue: DispatchQueue = .main, handle: @escaping (Int) -> Void) {
            self.interval = interval
            self.count = count
            self.handle = handle
            self.queue = queue
        }
        
        private var steps: Int = 0
        
        func fire() {
            steps += 1
            count -= 1
            guard count % interval == 0 else { return }
            queue.async { [weak self] in
                guard let `self` = self else { return }
                self.handle(self.count)
            }
        }
    }
    
    static let shared = STSchedule()
    
    public init() {
        self.timer = Timer(fireAt: Date.distantFuture, interval: 1.0, target: self, selector: #selector(timerScheduled), userInfo: nil, repeats: true)
        RunLoop.current.add(self.timer, forMode: RunLoop.Mode.common)
    }
    
    private var values = [AnyHashable : Value]()
    private var timer: Timer!
    private let queue = DispatchQueue(label: "com.st.schedule.queue")
}
