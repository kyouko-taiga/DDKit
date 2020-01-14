# DDKit

[![Build Status](https://travis-ci.org/kyouko-taiga/DDKit.svg?branch=master)](https://travis-ci.org/kyouko-taiga/DDKit)

DDKit is an embedded domain specific language that implements set and family decision diagrams (i.e. SFDDs and MFDDs).

Set and family decision diagrams are directed acyclic graphs capable of representing sets of data, exploiting similarities between individual elements to compact their representation.
They also support a variety of operations, called *morphisms*, that can be used to manipulate data efficiently.

## Installation

DDKit is provided in the form of a Swift package and can be integrated with the
[Swift Package Manager](https://swift.org/package-manager/).

Add DDKit as a dependency to your package in your `Pacakge.swift` file:

```swift
let package = Package(
  // ...
  dependencies: [
    .package(url: "https://github.com/kyouko-taiga/DDKit.git", .branch("master")),
  ],
  targets: [
    .target(name: "MyTarget", dependencies: ["DDKit"]),
  ],
  // ...
)
```

Note that latest releases will always be pushed to the `master` branch of the
[github repository](https://github.com/kyouko-taiga/DDKit.git).

Then, you may import `DDKit` into your project:

```swift
import DDKit
```

## Usage

DDKit provides two different decision diagram implementations: set family decision diagrams (SFDDs) and map family decision diagrams (MFDDs).
The former should be used to encode sets of data, while the latter should be used to encode sets of dictionaries.

For the sake of performance, DDKit uses its own memory allocation strategy.
Therefore, decision diagrams should be created by the means of a dedicated factory object:

```swift
import DDKit

let factory = MFDDFactory<Int, String>()
let diagram = factory.encode(family: [[0: "foo", 1: "bar"], [0: "bar", 1: "bar"]])
print(diagram)
// Prints [[1: "bar", 0: "bar"], [1: "bar", 0: "foo"]]
```

A factory operates similarly as a [hash table](https://en.wikipedia.org/wiki/Hash_table) that allocates memory in chunks of some size.
By default, each chunk is about 64KB (depending on the type of data being encoded).
You may want to increase this value if your application manipulates very large decision diagrams:

```swift
let factory = MFDDFactory<Int, String>(bucketCapacity: 1 << 20)
```

You can perform operations on decision diagrams through *morphisms*:

```swift
let morphism = factory.morphisms.insert(assignments: [2: "baz"])
print(morphism.apply(on: diagram))
// Prints [[1: "bar", 0: "foo", 2: "baz"], [1: "bar", 0: "bar", 2: "baz"]]
```

You can find more elaborate usage examples in the `Examples/` folder.

## License

DDKit is released under the MIT license.
