// ExONContainers+Decoding.swift
// Decoding containers for ExON
import Foundation

final class ExONKeyedDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
    typealias Key = Key
    let decoder: _SingleValueBoxDecoder
    var codingPath: [CodingKey] { decoder.codingPath }
    var allKeys: [Key] {
        // List all files/directories in baseURL
        guard let contents = try? decoder.fileManager.contentsOfDirectory(atPath: decoder.baseURL.path) else { return [] }
        return contents.compactMap { Key(stringValue: ($0 as NSString).deletingPathExtension) }
    }
    
    init(decoder: _SingleValueBoxDecoder) {
        self.decoder = decoder
    }
    
    func contains(_ key: Key) -> Bool {
        let url = decoder.baseURL.appendingPathComponent(key.stringValue)
        return decoder.fileManager.fileExists(atPath: url.path) || decoder.fileManager.fileExists(atPath: url.appendingPathExtension(decoder.fileExtension.trimmingCharacters(in: ["."])).path)
    }
    
    func decodeNil(forKey key: Key) throws -> Bool {
        let url = decoder.baseURL.appendingPathComponent(key.stringValue)
        let file = url.appendingPathExtension(decoder.fileExtension.trimmingCharacters(in: ["."]))
        return !(decoder.fileManager.fileExists(atPath: url.path) || decoder.fileManager.fileExists(atPath: file.path))
    }
    
    func decode<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
        let url = decoder.baseURL.appendingPathComponent(key.stringValue)
        if isBasicType(type) {
            let fileURL = url.appendingPathExtension(decoder.fileExtension.trimmingCharacters(in: ["."]))
            let data = try Data(contentsOf: fileURL)
            return try decodeBasicTypeFromData(type, data)
        } else {
            return try type.init(from: _SingleValueBoxDecoder(fileExtension: decoder.fileExtension, fileManager: decoder.fileManager, baseURL: url))
        }
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
        let url = decoder.baseURL.appendingPathComponent(key.stringValue)
        let subDecoder = _SingleValueBoxDecoder(fileExtension: decoder.fileExtension, fileManager: decoder.fileManager, baseURL: url)
        let container = ExONKeyedDecodingContainer<NestedKey>(decoder: subDecoder)
        return KeyedDecodingContainer(container)
    }
    
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        let url = decoder.baseURL.appendingPathComponent(key.stringValue)
        let subDecoder = _SingleValueBoxDecoder(fileExtension: decoder.fileExtension, fileManager: decoder.fileManager, baseURL: url)
        return ExONUnkeyedDecodingContainer(decoder: subDecoder)
    }
    
    func superDecoder() throws -> Decoder {
        return decoder
    }
    
    func superDecoder(forKey key: Key) throws -> Decoder {
        let url = decoder.baseURL.appendingPathComponent(key.stringValue)
        return _SingleValueBoxDecoder(fileExtension: decoder.fileExtension, fileManager: decoder.fileManager, baseURL: url)
    }
}

final class ExONUnkeyedDecodingContainer: UnkeyedDecodingContainer {
    let decoder: _SingleValueBoxDecoder
    var codingPath: [CodingKey] { decoder.codingPath }
    var count: Int?
    var currentIndex = 0
    private let contents: [String]
    
    init(decoder: _SingleValueBoxDecoder) {
        self.decoder = decoder
        let fileNames = (try? decoder.fileManager.contentsOfDirectory(atPath: decoder.baseURL.path)) ?? []
        // Only numeric filenames (array indices)
        self.contents = fileNames.sorted { (a, b) in
            guard let ai = Int((a as NSString).deletingPathExtension), let bi = Int((b as NSString).deletingPathExtension) else { return false }
            return ai < bi
        }
        self.count = contents.count
    }
    
    var isAtEnd: Bool { currentIndex >= (count ?? 0) }
    
    func decodeNil() throws -> Bool {
        let exists = currentIndex < contents.count
        if exists {
            let url = decoder.baseURL.appendingPathComponent(contents[currentIndex])
            let file = url.appendingPathExtension(decoder.fileExtension.trimmingCharacters(in: ["."]))
            let hasValue = decoder.fileManager.fileExists(atPath: url.path) || decoder.fileManager.fileExists(atPath: file.path)
            if !hasValue { currentIndex += 1 }; return !hasValue
        } else {
            currentIndex += 1; return true
        }
    }
    
    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        let file = contents[currentIndex]
        let url = decoder.baseURL.appendingPathComponent(file)
        if isBasicType(type) {
            let fileURL = url.pathExtension.isEmpty ? url.appendingPathExtension(decoder.fileExtension.trimmingCharacters(in: ["."])) : url
            let data = try Data(contentsOf: fileURL)
            currentIndex += 1
            return try decodeBasicTypeFromData(type, data)
        } else {
            let subDecoder = _SingleValueBoxDecoder(fileExtension: decoder.fileExtension, fileManager: decoder.fileManager, baseURL: url)
            let value = try type.init(from: subDecoder)
            currentIndex += 1
            return value
        }
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> {
        let file = contents[currentIndex]
        let url = decoder.baseURL.appendingPathComponent(file)
        let subDecoder = _SingleValueBoxDecoder(fileExtension: decoder.fileExtension, fileManager: decoder.fileManager, baseURL: url)
        let container = ExONKeyedDecodingContainer<NestedKey>(decoder: subDecoder)
        currentIndex += 1
        return KeyedDecodingContainer(container)
    }
    
    func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        let file = contents[currentIndex]
        let url = decoder.baseURL.appendingPathComponent(file)
        let subDecoder = _SingleValueBoxDecoder(fileExtension: decoder.fileExtension, fileManager: decoder.fileManager, baseURL: url)
        currentIndex += 1
        return ExONUnkeyedDecodingContainer(decoder: subDecoder)
    }
    
    func superDecoder() throws -> Decoder {
        return decoder
    }
}

final class ExONSingleValueDecodingContainer: SingleValueDecodingContainer {
    let decoder: _SingleValueBoxDecoder
    var codingPath: [CodingKey] { decoder.codingPath }
    
    init(decoder: _SingleValueBoxDecoder) {
        self.decoder = decoder
    }
    
    func decodeNil() -> Bool {
        // nil is absence of file/dir
        return false
    }
    
    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        print("Decoding: \(decoder.baseURL)")
        if isBasicType(type) {
            let fileURL = decoder.baseURL.appendingPathExtension(decoder.fileExtension.trimmingCharacters(in: ["."]))
            let data = try Data(contentsOf: fileURL)
            return try decodeBasicTypeFromData(type, data)
        } else {
            return try type.init(from: _SingleValueBoxDecoder(fileExtension: decoder.fileExtension, fileManager: decoder.fileManager, baseURL: decoder.baseURL))
        }
    }
}

