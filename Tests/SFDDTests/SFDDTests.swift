import XCTest
import DDKit

final class SFDDTests: XCTestCase {

  func testNodeCreation() {
    let factory = SFDDFactory<Int>(bucketCapacity: 4)

    _ = factory.encode(family: [0 ..< 10])
    XCTAssertEqual(factory.createdCount, 10)
  }

  func testCount() {
    let factory = SFDDFactory<Int>()

    XCTAssertEqual(0, factory.zero.count)
    XCTAssertEqual(1, factory.one.count)
    XCTAssertEqual(1, factory.encode(family: [[1, 2]]).count)
    XCTAssertEqual(2, factory.encode(family: [[1, 2], [1, 3]]).count)
    XCTAssertEqual(2, factory.encode(family: [[1, 2], []]).count)
  }

  func testEquates() {
    let factory = SFDDFactory<Int>()

    XCTAssertEqual(factory.zero, factory.zero)
    XCTAssertEqual(factory.one, factory.one)
    XCTAssertEqual(factory.encode(family: [[]]), factory.one)
    XCTAssertEqual(factory.encode(family: [[1, 2]]), factory.encode(family: [[1, 2]]))
  }

  func testContains() {
    let factory = SFDDFactory<Int>()
    var family: SFDD<Int>

    family = factory.zero
    XCTAssertFalse(family.contains([]))

    family = factory.one
    XCTAssert(family.contains([]))
    XCTAssertFalse(family.contains([1]))

    family = factory.encode(family: [[1]])
    XCTAssertFalse(family.contains([]))
    XCTAssert(family.contains([1]))
    XCTAssertFalse(family.contains([2]))

    family = factory.encode(family: [[1, 2], [1, 3], [1, 4]])
    XCTAssert(family.contains([1, 2]))
    XCTAssert(family.contains([1, 3]))
    XCTAssert(family.contains([1, 4]))
    XCTAssertFalse(family.contains([]))
    XCTAssertFalse(family.contains([1]))
    XCTAssertFalse(family.contains([1, 5]))
  }

  func testRandomElement() {
    let factory = SFDDFactory<Int>()

    XCTAssertNil(factory.zero.randomElement())
    XCTAssertEqual(factory.one.randomElement(), factory.one.randomElement())

    let family = factory.encode(family: [[1, 2, 3, 4], [1, 3, 4], [2, 3, 4]])
    let member = family.randomElement()
    XCTAssertNotNil(member)
    if member != nil {
      XCTAssert(Set([[1, 2, 3, 4], [1, 3, 4], [2, 3, 4]]).contains(member!))
    }
  }

  func testBinaryUnion() {
    let factory = SFDDFactory<Int>()
    var a, b: SFDD<Int>

    // Union of two identical families.
    a = factory.encode(family: [[], [3, 5], [1, 3, 5]])
    XCTAssertEqual(a.union(a), a)

    // Union of two different families.
    a = factory.encode(family: [[], [3, 5], [1, 3, 5]])
    b = factory.encode(family: [[3, 5], [1, 3, 5], [4, 7]])
    XCTAssertEqual(Set(a.union(b)), Set([[], [3, 5], [1, 3, 5], [4, 7]].map(Set.init)))

    // Union with a sequence of members.
    a = factory.encode(family: [[], [3, 5], [1, 3, 5]])
    let c = [[3, 5], [1, 3, 5], [4, 7]]
    XCTAssertEqual(Set(a.union(c)), Set([[], [3, 5], [1, 3, 5], [4, 7]].map(Set.init)))
  }

  func testNaryUnion() {
    let factory = SFDDFactory<Int>()
    let dd = factory.encode(family: [[], [3, 5], [1, 3, 5]])

    // Union with an empty sequence of families.
    XCTAssertEqual(dd.union(others: []), dd)

    // Union with a single family.
    let au1 = dd.union(others: [factory.encode(family: [[3, 5], [1, 3, 5], [4, 7]])])
    XCTAssertEqual(Set(au1), Set([[], [3, 5], [1, 3, 5], [4, 7]].map(Set.init)))

    // Union with two families.
    let au2 = dd.union(others: [
      factory.encode(family: [[1, 3, 5], [4, 7]]),
      factory.encode(family: [[3, 5], [1, 3, 5]])
    ])
    XCTAssertEqual(Set(au2), Set([[], [3, 5], [1, 3, 5], [4, 7]].map(Set.init)))
  }

  func testBinaryIntersection() {
    let factory = SFDDFactory<Int>()
    var a, b: SFDD<Int>

    // Intersection of two identical families.
    a = factory.encode(family: [[], [3, 5], [1, 3, 5]])
    XCTAssertEqual(a.intersection(a), a)

    // Intersection of two different families.
    a = factory.encode(family: [[], [3, 5], [1, 3, 5]])
    b = factory.encode(family: [[3, 5], [1, 3, 5], [4, 7]])
    XCTAssertEqual(Set(a.intersection(b)), Set([[3, 5], [1, 3, 5]].map(Set.init)))

    // Intersection with a sequence of members.
    a = factory.encode(family: [[], [3, 5], [1, 3, 5]])
    let c = [[3, 5], [1, 3, 5], [4, 7]]
    XCTAssertEqual(Set(a.intersection(c)), Set([[3, 5], [1, 3, 5]].map(Set.init)))
  }

  func testNaryIntersection() {
    let factory = SFDDFactory<Int>()
    let dd = factory.encode(family: [[], [3, 5], [1, 3, 5]])

    // Union with an empty sequence of families.
    XCTAssertEqual(dd.intersection(others: []), dd)

    // Union with a single family.
    let au1 = dd.intersection(others: [factory.encode(family: [[3, 5], [1, 3, 5], [4, 7]])])
    XCTAssertEqual(Set(au1), Set([[3, 5], [1, 3, 5]].map(Set.init)))

    // Union with two families.
    let au2 = dd.intersection(others: [
      factory.encode(family: [[1, 3, 5], [4, 7]]),
      factory.encode(family: [[3, 5], [1, 3, 5]])
    ])
    XCTAssertEqual(Set(au2), Set([[1, 3, 5]].map(Set.init)))

    let au3 = dd.intersection(others: [factory.one, factory.encode(family: [[3, 5], [1, 3, 5]])])
    XCTAssertEqual(Set(au3), Set())
  }

  func testBinarySymmetricDifference() {
    let factory = SFDDFactory<Int>()
    var a, b: SFDD<Int>

    // Symmetric difference between two identical families.
    a = factory.encode(family: [[], [3, 5], [1, 3, 5]])
    XCTAssertEqual(a.symmetricDifference(a), factory.zero)

    // Symmetric difference between two different families.
    a = factory.encode(family: [[], [3, 5], [1, 3, 5]])
    b = factory.encode(family: [[3, 5], [1, 3, 5], [4, 7]])
    XCTAssertEqual(Set(a.symmetricDifference(b)), Set([[], [4, 7]].map(Set.init)))

    // Symmetric difference with a sequence of members.
    a = factory.encode(family: [[], [3, 5], [1, 3, 5]])
    let c = [[3, 5], [1, 3, 5], [4, 7]]
    XCTAssertEqual(Set(a.symmetricDifference(c)), Set([[], [4, 7]].map(Set.init)))
  }

  func testSubtraction() {
    let factory = SFDDFactory<Int>()
    var a, b: SFDD<Int>

    // Subtraction of a family by itself.
    a = factory.encode(family: [[], [3, 5], [1, 3, 5]])
    XCTAssertEqual(a.subtracting(a), factory.zero)

    // Subtraction of a family by a different one.
    a = factory.encode(family: [[], [3, 5], [1, 3, 5]])
    b = factory.encode(family: [[3, 5], [1, 3, 5], [4, 7]])
    XCTAssertEqual(Set(a.subtracting(b)), Set([[]].map(Set.init)))

    // Subtraction of a family by a sequence of members.
    a = factory.encode(family: [[], [3, 5], [1, 3, 5]])
    let c = [[3, 5], [1, 3, 5], [4, 7]]
    XCTAssertEqual(Set(a.subtracting(c)), Set([[]].map(Set.init)))
  }

}
