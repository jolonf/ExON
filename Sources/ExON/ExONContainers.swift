// ExONContainers.swift
// Contains the keyed, unkeyed, and single value encoding/decoding containers for ExON
import Foundation

// MARK: - Keyed Encoding Container

final class ExONKeyedEncodingContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
    typealias Key = Key
    
    let encoder: _SingleValueBoxEncoder
    var codingPath: [CodingKey] { encoder.codingPath }
    
    init(encoder: _SingleValueBoxEncoder) {
        self.encoder = encoder
    }
    
    func encodeNil(forKey key: Key) throws {
        // Nil is represented by absence of file/dir: do nothing
    }
    
    func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
        let url = encoder.baseURL.appendingPathComponent(key.stringValue)
        print("Encoding: \(url)")
        if isBasicType(value) {
            let fileURL = url.appendingPathExtension(encoder.fileExtension.trimmingCharacters(in: ["."]))
            print("ext: \(encoder.fileExtension)")
            print("Encoding (with ext): \(fileURL)")
            let data = try encodeBasicTypeToData(value)
            try data.write(to: fileURL, options: .atomic)
        } else {
            // Complex type: make dir and encode inside
            try encoder.fileManager.createDirectory(at: url, withIntermediateDirectories: true)
            let subEncoder = _SingleValueBoxEncoder(fileExtension: encoder.fileExtension, fileManager: encoder.fileManager, baseURL: url)
            try value.encode(to: subEncoder)
        }
    }
    
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
        let url = encoder.baseURL.appendingPathComponent(key.stringValue)
        let subEncoder = _SingleValueBoxEncoder(fileExtension: encoder.fileExtension, fileManager: encoder.fileManager, baseURL: url)
        let container = ExONKeyedEncodingContainer<NestedKey>(encoder: subEncoder)
        return KeyedEncodingContainer(container)
    }
    
    func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        let url = encoder.baseURL.appendingPathComponent(key.stringValue)
        let subEncoder = _SingleValueBoxEncoder(fileExtension: encoder.fileExtension, fileManager: encoder.fileManager, baseURL: url)
        return ExONUnkeyedEncodingContainer(encoder: subEncoder)
    }
    
    func superEncoder() -> Encoder {
        return encoder
    }
    
    func superEncoder(forKey key: Key) -> Encoder {
        let url = encoder.baseURL.appendingPathComponent(key.stringValue)
        return _SingleValueBoxEncoder(fileExtension: encoder.fileExtension, fileManager: encoder.fileManager, baseURL: url)
    }
}

// MARK: - Unkeyed Encoding Container

final class ExONUnkeyedEncodingContainer: UnkeyedEncodingContainer {
    let encoder: _SingleValueBoxEncoder
    var codingPath: [CodingKey] { encoder.codingPath }
    var count: Int = 0
    
    init(encoder: _SingleValueBoxEncoder) {
        self.encoder = encoder
    }
    
    func encodeNil() throws {
        // Nil is represented by absence of file/dir: do nothing
        count += 1
    }
    
    func encode<T: Encodable>(_ value: T) throws {
        let url = encoder.baseURL.appendingPathComponent(String(count))
        if isBasicType(value) {
            let fileURL = url.appendingPathExtension(encoder.fileExtension.trimmingCharacters(in: ["."]))
            let data = try encodeBasicTypeToData(value)
            try data.write(to: fileURL, options: .atomic)
        } else {
            try encoder.fileManager.createDirectory(at: url, withIntermediateDirectories: true)
            let subEncoder = _SingleValueBoxEncoder(fileExtension: encoder.fileExtension, fileManager: encoder.fileManager, baseURL: url)
            try value.encode(to: subEncoder)
        }
        count += 1
    }
    
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
        let url = encoder.baseURL.appendingPathComponent(String(count))
        let subEncoder = _SingleValueBoxEncoder(fileExtension: encoder.fileExtension, fileManager: encoder.fileManager, baseURL: url)
        let container = ExONKeyedEncodingContainer<NestedKey>(encoder: subEncoder)
        count += 1
        return KeyedEncodingContainer(container)
    }
    
    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        let url = encoder.baseURL.appendingPathComponent(String(count))
        let subEncoder = _SingleValueBoxEncoder(fileExtension: encoder.fileExtension, fileManager: encoder.fileManager, baseURL: url)
        count += 1
        return ExONUnkeyedEncodingContainer(encoder: subEncoder)
    }
    
    func superEncoder() -> Encoder {
        return encoder
    }
}

// MARK: - Single Value Encoding Container

final class ExONSingleValueEncodingContainer: SingleValueEncodingContainer {
    let encoder: _SingleValueBoxEncoder
    var codingPath: [CodingKey] { encoder.codingPath }
    
    init(encoder: _SingleValueBoxEncoder) {
        self.encoder = encoder
    }
    
    func encodeNil() throws {
        // Nil is represented by absence of file/dir: do nothing
    }

    func encode<T: Encodable>(_ value: T) throws {
        print("Encoding: \(encoder.baseURL)")
        if isBasicType(value) {
            let fileURL = encoder.baseURL.appendingPathExtension(encoder.fileExtension.trimmingCharacters(in: ["."]))
            let data = try encodeBasicTypeToData(value)
            try data.write(to: fileURL, options: .atomic)
        } else {
            let subEncoder = _SingleValueBoxEncoder(fileExtension: encoder.fileExtension, fileManager: encoder.fileManager, baseURL: encoder.baseURL)
            try value.encode(to: subEncoder)
        }
    }
}

