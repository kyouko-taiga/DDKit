import XCTest
import DDKit

final class MFDDTests: XCTestCase {

  func testNodeCreation() {
    let factory = MFDDFactory<Int, String>(bucketCapacity: 4)

    _ = factory.encode(family: [(0 ..< 10).map({ (key: $0, value: String(describing: $0)) })])
    XCTAssertEqual(factory.createdCount, 10)
  }

  func testCount() {
    let factory = MFDDFactory<Int, String>()

    XCTAssertEqual(0, factory.zero.count)
    XCTAssertEqual(1, factory.one.count)
    XCTAssertEqual(1, factory.encode(family: [[1: "a", 2: "b"]]).count)
    XCTAssertEqual(2, factory.encode(family: [[1: "a", 2: "b"], [1: "a", 3: "c"]]).count)
    XCTAssertEqual(2, factory.encode(family: [[1: "a", 2: "b"], [:]]).count)
  }

  func testEquates() {
    let factory = MFDDFactory<Int, String>()

    XCTAssertEqual(factory.zero, factory.zero)
    XCTAssertEqual(factory.one, factory.one)
    XCTAssertEqual(factory.encode(family: [[:]]), factory.one)
    XCTAssertEqual(
      factory.encode(family: [[1: "a", 2: "b"]]),
      factory.encode(family: [[1: "a", 2: "b"]]))
  }

  func testContains() {
    let factory = MFDDFactory<Int, String>()
    var family: MFDD<Int, String>

    family = factory.zero
    XCTAssertFalse(family.contains([:]))

    family = factory.one
    XCTAssert(family.contains([:]))
    XCTAssertFalse(family.contains([1: "a"]))

    family = factory.encode(family: [[1: "a"]])
    XCTAssertFalse(family.contains([]))
    XCTAssert(family.contains([1: "a"]))
    XCTAssertFalse(family.contains([1: "b"]))
    XCTAssertFalse(family.contains([2: "a"]))

    family = factory.encode(family: [[1: "a", 2: "b"], [1: "a", 3: "c"], [1: "a", 4: "d"]])
    XCTAssert(family.contains([1: "a", 2: "b"]))
    XCTAssert(family.contains([1: "a", 3: "c"]))
    XCTAssert(family.contains([1: "a", 4: "d"]))
    XCTAssertFalse(family.contains([]))
    XCTAssertFalse(family.contains([1: "a"]))
    XCTAssertFalse(family.contains([1: "a", 5: "e"]))
  }

  func testRandomElement() {
    let factory = MFDDFactory<Int, String>()

    XCTAssertNil(factory.zero.randomElement())
    XCTAssertEqual(factory.one.randomElement(), factory.one.randomElement())

    let decoded: [[Int: String]] = [
      [1: "", 2: "abc", 3: "def", 4: "ghi"],
      [1: "", 3: "def", 4: "ghi"],
      [2: "abc", 3: "def", 4: "ghi"],
    ]

    let family = factory.encode(family: decoded)
    let member = family.randomElement()
    XCTAssertNotNil(member)
    if member != nil {
      XCTAssert(decoded.contains(member!))
    }
  }

  func testBinaryUnion() {
    let factory = MFDDFactory<Int, String>()
    var a, b: MFDD<Int, String>

    // Union of two identical families.
    a = factory.encode(family: [[:], [3: "c", 5: "e"], [1: "a", 3: "c", 5: "e"]])
    XCTAssertEqual(a.union(a), a)

    // Union of two different families.
    a = factory.encode(family: [[:], [3: "a", 5: "e"], [1: "a", 3: "c", 5: "e"]])
    b = factory.encode(family: [[3: "a", 5: "e"], [3: "a", 5: "E"]])
    XCTAssertEqual(
      Set(a.union(b)),
      Set([[:], [3: "a", 5: "e"], [1: "a", 3: "c", 5: "e"], [3: "a", 5: "E"]]))

    // Union with a sequence of members.
    a = factory.encode(family: [[:], [3: "a", 5: "e"], [1: "a", 3: "c", 5: "e"]])
    let c = [[3: "a", 5: "e"], [3: "a", 5: "E"]]
    XCTAssertEqual(
      Set(a.union(c)),
      Set([[:], [3: "a", 5: "e"], [1: "a", 3: "c", 5: "e"], [3: "a", 5: "E"]]))
  }

  func testBinaryIntersection() {
    let factory = MFDDFactory<Int, String>()
    var a, b: MFDD<Int, String>

    // Intersection of two identical families.
    a = factory.encode(family: [[:], [3: "c", 5: "e"], [1: "a", 3: "c", 5: "e"]])
    XCTAssertEqual(a.intersection(a), a)

    // Intersection of two different families.
    a = factory.encode(family: [[:], [3: "a", 5: "e"], [1: "a", 3: "c", 5: "e"]])
    b = factory.encode(family: [[3: "a", 5: "e"], [3: "a", 5: "E"]])
    XCTAssertEqual(Set(a.intersection(b)), Set([[3: "a", 5: "e"]]))

    // Intersection with a sequence of members.
    a = factory.encode(family: [[:], [3: "a", 5: "e"], [1: "a", 3: "c", 5: "e"]])
    let c = [[3: "a", 5: "e"], [3: "a", 5: "E"]]
    XCTAssertEqual(Set(a.intersection(c)), Set([[3: "a", 5: "e"]]))
  }

  func testBinarySymmetricDifference() {
    let factory = MFDDFactory<Int, String>()
    var a, b: MFDD<Int, String>

    // Symmetric difference between two identical families.
    a = factory.encode(family: [[:], [3: "c", 5: "e"], [1: "a", 3: "c", 5: "e"]])
    XCTAssertEqual(a.symmetricDifference(a), factory.zero)

    // Symmetric difference between two different families.
    a = factory.encode(family: [[:], [3: "a", 5: "e"], [1: "a", 3: "c", 5: "e"]])
    b = factory.encode(family: [[3: "a", 5: "e"], [3: "a", 5: "E"]])
    XCTAssertEqual(
      Set(a.symmetricDifference(b)),
      Set([[:], [1: "a", 3: "c", 5: "e"], [3: "a", 5: "E"]]))

    // Symmetric difference with a sequence of members.
    a = factory.encode(family: [[:], [3: "a", 5: "e"], [1: "a", 3: "c", 5: "e"]])
    let c = [[3: "a", 5: "e"], [3: "a", 5: "E"]]
    XCTAssertEqual(
      Set(a.symmetricDifference(c)),
      Set([[:], [1: "a", 3: "c", 5: "e"], [3: "a", 5: "E"]]))
  }

  func testSubtraction() {
    let factory = MFDDFactory<Int, String>()
    var a, b: MFDD<Int, String>

    // Subtraction of a family by itself.
    a = factory.encode(family: [[:], [3: "c", 5: "e"], [1: "a", 3: "c", 5: "e"]])
    XCTAssertEqual(a.subtracting(a), factory.zero)

    // Subtraction of a family by a different one.
    a = factory.encode(family: [[:], [3: "a", 5: "e"], [1: "a", 3: "c", 5: "e"]])
    b = factory.encode(family: [[3: "a", 5: "e"], [3: "a", 5: "E"]])
    XCTAssertEqual(Set(a.subtracting(b)), Set([[:], [1: "a", 3: "c", 5: "e"]]))
    
    // Subtraction of a family by a different one.
    a = factory.encode(family: [[:], [3: "a", 5: "e"], [3: "a", 5: "f"], [1: "z", 2: "p"], [1: "z", 2: "e"]])
    b = factory.encode(family: [[3: "a", 5: "e"], [1: "z", 2: "e"]])
    XCTAssertEqual(Set(a.subtracting(b)), Set([[:], [3: "a", 5: "f"], [1: "z", 2: "p"]]))

    // Subtraction of a family by a sequence of members.
    a = factory.encode(family: [[:], [3: "a", 5: "e"], [1: "a", 3: "c", 5: "e"]])
    let c = [[3: "a", 5: "e"], [3: "a", 5: "E"]]
    XCTAssertEqual(Set(a.subtracting(c)), Set([[:], [1: "a", 3: "c", 5: "e"]]))
  }

}
