# ExON library

Exon is a Swift package library which serialises objects to the ExON (Exploded Object Notation) format.

## ExON (Exploded Object Notation) format

ExON, whose name is a take off of JSON, is a way to serialise objects using file system primitives.

All properties are either stored in a file or directory, where the name of the file/directory is the property name.

All basic types have their data stored directly in a `.txt` file whereas objects and collections are stored in directories.

### Basic types

An object of the following class with properties with basic types:

```swift

class Person: Codable {
    var name: String
    var age: Int
}

```

would be stored as the following text files:

```
├── name.txt
└── age.txt
```

### Arrays/Dictionaries

Arrays and dictionaries use a directory where each file is named with the key of the entry. For arrays the key is the index.

```swift
class Student: Codable {
    var name: String
    var grades: [Int]
}
```

```
├── name.txt
└── grades/
  ├── 0.txt
  ├── 1.txt
  ├── 2.txt
  └── ...

```

The above example uses a basic type for the array element, if a complex type is used then each entry is a directory:

```swift
class Cart: Codable {
    var timestamp: Date
    var items: [Item]
}

class Item: Codable {
    var name: String
    var price: Int
}
```

```
├── timestamp.txt
└── items/
    ├── 0/
    │   ├── name.txt
    │   └── price.txt
    ├── 1/
    │   ├── name.txt
    │   └── price.txt
    ├── 2/
    │   ├── name.txt
    │   └── price.txt
    └── ...
```

## Codable

Like defining types that can be serialised to JSON, all types must be either Encodable, Decodable, or Codable.

## Using ExON

### ExONEncoder()

```swift

import ExON

struct Person: Codable {
    var name: String
    var age: Int
}

let person = Person(name: "Alice", age: 38)
let encoder = ExONEncoder()
let baseURL = URL("~/Desktop/person")
try encoder.encode(person, to: baseURL)
```

### ExONDecoder()

```swift

import ExON

struct Person: Codable {
    var name: String
    var age: Int
}

let decoder = ExONDecoder()
let baseURL = URL("~/Desktop/person")
let decoded = try decoder.decode(Person.self, from: baseURL)
```

## Data Types Supported

- Optionals
  - nil value does not write a file or directory
  - Missing file or directory has nil value
- Enums
- String
- Int
- Double
- Array
- Dictionary
- Nested structs
