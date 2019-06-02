//
//  SleepWorker.swift
//  Modernistik
//
//  Created by Anthony Persaud on 5/15/17.
//

import Foundation

public class SleepWorker : Worker {
    public var seconds: TimeInterval = 5
    public static func enqueue(sleep: TimeInterval) {
        let op = SleepWorker()
        op.seconds = sleep
        op.enqueue()
    }
    
    override public func work() {
        
        Thread.sleep(forTimeInterval: seconds)
        completed()
    }
}
