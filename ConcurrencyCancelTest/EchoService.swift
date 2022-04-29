//
//  EchoService.swift
//  ConcurrencyCancelTest
//
//  Created by k2o on 2022/04/29.
//

import Foundation

final class EchoService {
    static let shared = EchoService()

    private let delay: TimeInterval = 3
    
    private init() {}
    
    func echo(_ string: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                continuation.resume(returning: string)
            }
        }
    }

    private class ValueHolder<V> {
        var value: V
        
        init(_ value: V) {
            self.value = value
        }
    }
    
    func echoCancellable(_ string: String) async throws -> String {
        let isCancelled = ValueHolder(false)
        return try await withTaskCancellationHandler(
            operation: {
                return try await withCheckedThrowingContinuation { continuation in
                    DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                        if isCancelled.value {
                            continuation.resume(throwing: CancellationError())
                        } else {
                            continuation.resume(returning: string)
                        }
                    }
                }
            }, onCancel: {
                print("cancel echo")
                isCancelled.value = true
            }
        )
    }
}
