import Testing
import Foundation
@testable import ExON

@Suite("ExON Encoding/Decoding Core Tests")
struct ExONCoreTests {
    let tempDir: URL = {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }()

    struct Person: Codable, Equatable {
        var name: String
        var age: Int
    }

    @Test("Basic encode and decode of Person struct")
    func testPersonRoundTrip() throws {
        let encoder = ExONEncoder()
        let decoder = ExONDecoder()
        let base = tempDir.appendingPathComponent("person")
        let alice = Person(name: "Alice", age: 38)
        try encoder.encode(alice, to: base)
        let decoded = try decoder.decode(Person.self, from: base)
        #expect(decoded == alice)
    }

    struct Student: Codable, Equatable {
        var name: String
        var grades: [Int]
    }

    @Test("Encode/decode array properties")
    func testStudentGrades() throws {
        let encoder = ExONEncoder()
        let decoder = ExONDecoder()
        let base = tempDir.appendingPathComponent("student")
        let s = Student(name: "Bob", grades: [90, 87, 99])
        try encoder.encode(s, to: base)
        let decoded = try decoder.decode(Student.self, from: base)
        #expect(decoded == s)
    }

    struct Item: Codable, Equatable {
        var name: String
        var price: Int
    }
    struct Cart: Codable, Equatable {
        var timestamp: Date
        var items: [Item]
    }

    @Test("Nested struct and array round-trip")
    func testCartItems() throws {
        let encoder = ExONEncoder()
        let decoder = ExONDecoder()
        let base = tempDir.appendingPathComponent("cart")
        let now = Date()
        let cart = Cart(timestamp: now, items: [Item(name: "apple", price: 2), Item(name: "orange", price: 4)])
        try encoder.encode(cart, to: base)
        let decoded = try decoder.decode(Cart.self, from: base)
        
        #expect(decoded.items.count == 2)
        #expect(decoded.items[0].name == "apple")
        #expect(Int(decoded.timestamp.timeIntervalSince1970) == Int(now.timeIntervalSince1970))
    }
    
    enum Grade: String, Codable, Equatable { case A, B, C }
    struct EnumTest: Codable, Equatable {
        var g: Grade?
    }
    @Test("Optional and enum support")
    func testEnumAndOptional() throws {
        let encoder = ExONEncoder()
        let decoder = ExONDecoder()
        let base = tempDir.appendingPathComponent("enumtest")
        let v = EnumTest(g: .A)
        try encoder.encode(v, to: base)
        let decoded = try decoder.decode(EnumTest.self, from: base)
        #expect(decoded == v)
        let v2 = EnumTest(g: nil)
        let base2 = tempDir.appendingPathComponent("enumtest2")
        try encoder.encode(v2, to: base2)
        let decoded2 = try decoder.decode(EnumTest.self, from: base2)
        #expect(decoded2 == v2)
    }
    
    @Test("Encode and decode top-level Int")
    func testTopLevelIntEncodeDecode() throws {
        let encoder = ExONEncoder()
        let decoder = ExONDecoder()
        let base = tempDir.appendingPathComponent("topLevelInt")
        let number: Int = 12345
        try encoder.encode(number, to: base)
        // Check the file exists and contents
        let fileURL = base.appendingPathExtension("txt")
        let contents = try String(contentsOf: fileURL)
        #expect(contents.trimmingCharacters(in: .whitespacesAndNewlines) == String(number))
        // Decode back
        let decoded = try decoder.decode(Int.self, from: base)
        #expect(decoded == number)
    }
}
