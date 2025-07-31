// ExONEncoder.swift
// Core encoder for ExON (Exploded Object Notation)
import Foundation

/// Errors thrown during encoding.
public enum ExONEncodingError: Error {
    case invalidURL
    case unsupportedType(String)
    case encodingFailed(String)
    case fileWriteError(String)
}

/// The main encoder for ExON format.
public final class ExONEncoder {
    public let fileExtension: String
    private let fileManager: FileManager
    private let queue = DispatchQueue(label: "ExONEncoder.queue", attributes: .concurrent)
    
    /// Initialize with a custom extension (default is ".txt").
    public init(fileExtension: String = ".txt", fileManager: FileManager = .default) {
        var ext = fileExtension
        if !ext.hasPrefix(".") { ext = "." + ext }
        self.fileExtension = ext
        self.fileManager = fileManager
    }
    
    /// Encode synchronously.
    public func encode<T: Encodable>(_ value: T, to url: URL) throws {
        // Dispatch to serial queue for thread-safety.
        try queue.sync(flags: .barrier) {
            // Ensure that the base path exists
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
            let encoder = _ExONInternalEncoder(fileExtension: fileExtension, fileManager: fileManager, baseURL: url)
            try encoder.encode(value)
        }
    }
    
    /// Encode asynchronously.
    public func encode<T: Encodable>(_ value: T, to url: URL) async throws {
        try await withCheckedThrowingContinuation { continuation in
            queue.async(flags: .barrier) {
                do {
                    // Ensure that the base path exists
                    try self.fileManager.createDirectory(at: url, withIntermediateDirectories: true)
                    let encoder = _ExONInternalEncoder(fileExtension: self.fileExtension, fileManager: self.fileManager, baseURL: url)
                    try encoder.encode(value)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - Internal Encoder

fileprivate class _ExONInternalEncoder {
    let fileExtension: String
    let fileManager: FileManager
    let baseURL: URL
    
    init(fileExtension: String, fileManager: FileManager, baseURL: URL) {
        self.fileExtension = fileExtension
        self.fileManager = fileManager
        self.baseURL = baseURL
    }
    
    func encode<T: Encodable>(_ value: T) throws {
        try encode(value, at: baseURL)
    }
    
    private func encode<T: Encodable>(_ value: T, at url: URL) throws {
        let encoder = _SingleValueBoxEncoder(fileExtension: fileExtension, fileManager: fileManager, baseURL: url)
        try value.encode(to: encoder)
    }
}

// MARK: - Box Encoder

class _SingleValueBoxEncoder: Encoder {
    let fileExtension: String
    let fileManager: FileManager
    let baseURL: URL
    
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    init(fileExtension: String, fileManager: FileManager, baseURL: URL) {
        self.fileExtension = fileExtension
        self.fileManager = fileManager
        self.baseURL = baseURL
    }
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
        let container = ExONKeyedEncodingContainer<Key>(encoder: self)
        return KeyedEncodingContainer(container)
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        return ExONUnkeyedEncodingContainer(encoder: self)
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        return ExONSingleValueEncodingContainer(encoder: self)
    }
}

