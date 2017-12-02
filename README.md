# DDKit

[![Build Status](https://travis-ci.org/kyouko-taiga/DDKit.svg?branch=master)](https://travis-ci.org/kyouko-taiga/DDKit)

DDKit is a library of Decision Diagrams (DDs) pure Swift implementations.

DDs are data structures capable of representing large sets of data.
They take advantage of the similarities between individual elements
to compact their representation in a graph-like structure,
and support efficient operations to manipulate multiple elements at once.

## Provided Implementations

- [ ] Binary Decision Diagrams (BDDs)
- [x] Yet another Decision Diagrams (YDDs)
- [ ] Data Decision Diagrams (DDDs)
- [ ] Sigma Decision Diagrams (ΣDDs)

## Installation

DDKit is provided in the form of a Swift package and can be integrated with the
[Swift Package Manager](https://swift.org/package-manager/).

Add DDKit as a dependency to your package in your `Pacakge.swift` file:

```swift
import PackageDescription

let package = Package(
  // ...
  dependencies: [
    .Package(url: "https://github.com/kyouko-taiga/DDKit.git", branch: "master")
  ])
```

Note that latest releases will always be pushed to the `master` branch of the
[github repository](https://github.com/kyouko-taiga/DDKit.git).

## License

DDKit is released under the MIT license.
