// ExONDecoder.swift
// Core decoder for ExON (Exploded Object Notation)
import Foundation

/// Errors thrown during decoding.
public enum ExONDecodingError: Error {
    case invalidURL
    case unsupportedType(String)
    case decodingFailed(String)
    case fileReadError(String)
}

/// The main decoder for ExON format.
public final class ExONDecoder {
    public let fileExtension: String
    private let fileManager: FileManager
    private let queue = DispatchQueue(label: "ExONDecoder.queue", attributes: .concurrent)
    
    /// Initialize with a custom extension (default is ".txt").
    public init(fileExtension: String = ".txt", fileManager: FileManager = .default) {
        var ext = fileExtension
        if !ext.hasPrefix(".") { ext = "." + ext }
        self.fileExtension = ext
        self.fileManager = fileManager
    }
    
    /// Decode synchronously.
    public func decode<T: Decodable>(_ type: T.Type, from url: URL) throws -> T {
        return try queue.sync {
            let decoder = _ExONInternalDecoder(fileExtension: fileExtension, fileManager: fileManager, baseURL: url)
            return try decoder.decode(type)
        }
    }
}

// MARK: - Internal Decoder

fileprivate class _ExONInternalDecoder {
    let fileExtension: String
    let fileManager: FileManager
    let baseURL: URL
    
    init(fileExtension: String, fileManager: FileManager, baseURL: URL) {
        self.fileExtension = fileExtension
        self.fileManager = fileManager
        self.baseURL = baseURL
    }
    
    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        return try decode(type, at: baseURL)
    }
    
    private func decode<T: Decodable>(_ type: T.Type, at url: URL) throws -> T {
        let decoder = _SingleValueBoxDecoder(fileExtension: fileExtension, fileManager: fileManager, baseURL: url)
        return try T(from: decoder)
    }
}

// MARK: - Box Decoder

class _SingleValueBoxDecoder: Decoder {
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
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedDecodingContainer<Key> where Key: CodingKey {
        let container = ExONKeyedDecodingContainer<Key>(decoder: self)
        return KeyedDecodingContainer(container)
    }
    
    func unkeyedContainer() -> UnkeyedDecodingContainer {
        return ExONUnkeyedDecodingContainer(decoder: self)
    }
    
    func singleValueContainer() -> SingleValueDecodingContainer {
        return ExONSingleValueDecodingContainer(decoder: self)
    }
}

