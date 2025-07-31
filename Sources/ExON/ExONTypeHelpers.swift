// ExONTypeHelpers.swift
// Helpers for checking types and (de)serializing basic types for ExON
import Foundation

func isBasicType<T>(_ value: T) -> Bool {
    switch value {
    case is String, is Int, is Double, is Bool, is Float, is Date, is URL, is UUID:
        return true
    case let v as RawRepresentable where v.rawValue is String || v.rawValue is Int:
        return true
    default:
        return false
    }
}

func isBasicType(_ type: Any.Type) -> Bool {
    return type == String.self || type == Int.self || type == Double.self || type == Bool.self || type == Float.self || type == Date.self || type == URL.self || type == UUID.self
}

func encodeBasicTypeToData<T>(_ value: T) throws -> Data {
    switch value {
    case let v as String:
        return v.data(using: .utf8) ?? Data()
    case let v as Int:
        return String(v).data(using: .utf8) ?? Data()
    case let v as Double:
        return String(v).data(using: .utf8) ?? Data()
    case let v as Bool:
        return (v ? "1" : "0").data(using: .utf8) ?? Data()
    case let v as Float:
        return String(v).data(using: .utf8) ?? Data()
    case let v as Date:
        // Use ISO8601 for date string
        return v.formatted(.iso8601).data(using: .utf8) ?? Data()
    case let v as URL:
        return v.absoluteString.data(using: .utf8) ?? Data()
    case let v as UUID:
        return v.uuidString.data(using: .utf8) ?? Data()
    case let v as RawRepresentable:
        if let raw = v.rawValue as? String {
            return raw.data(using: .utf8) ?? Data()
        } else if let raw = v.rawValue as? Int {
            return String(raw).data(using: .utf8) ?? Data()
        }
        throw ExONEncodingError.unsupportedType("RawRepresentable type not supported: \(type(of: value))")
    default:
        throw ExONEncodingError.unsupportedType("Basic type not supported: \(type(of: value))")
    }
}

func decodeBasicTypeFromData<T>(_ type: T.Type, _ data: Data) throws -> T {
    if type == String.self, let str = String(data: data, encoding: .utf8) as? T {
        return str
    } else if type == Int.self, let s = String(data: data, encoding: .utf8), let i = Int(s) as? T {
        return i
    } else if type == Double.self, let s = String(data: data, encoding: .utf8), let d = Double(s) as? T {
        return d
    } else if type == Bool.self, let s = String(data: data, encoding: .utf8), let b = (s == "1" ? true : false) as? T {
        return b
    } else if type == Float.self, let s = String(data: data, encoding: .utf8), let f = Float(s) as? T {
        return f
    } else if type == Date.self, let s = String(data: data, encoding: .utf8), let d = try Date(s, strategy: .iso8601) as? T {
        return d
    } else if type == URL.self, let s = String(data: data, encoding: .utf8), let u = URL(string: s) as? T {
        return u
    } else if type == UUID.self, let s = String(data: data, encoding: .utf8), let u = UUID(uuidString: s) as? T {
        return u
    }
    throw ExONDecodingError.unsupportedType("Cannot decode type: \(type)")
}
