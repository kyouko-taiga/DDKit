import XCTest
import DDKit

final class MorphismsTests: XCTestCase {

  let factory = SFDDFactory<Int>()

  var morphisms: SFDDMorphismFactory<Int> { factory.morphisms }

  func testIdentity() {
    let morphism = morphisms.identity

    XCTAssertEqual(morphism.apply(on: factory.zero), factory.zero)
    XCTAssertEqual(morphism.apply(on: factory.one), factory.one)
    XCTAssertEqual(
      morphism.apply(on: factory.encode(family: [[1, 2], [1, 3]])),
      factory.encode(family: [[1, 2], [1, 3]]))
  }

  func testConstant() {
    let family = factory.encode(family: [[4, 2], [1, 3], [3, 7]])
    let morphism = morphisms.constant(family)

    XCTAssertEqual(morphism.apply(on: factory.zero), family)
    XCTAssertEqual(morphism.apply(on: factory.one), family)
    XCTAssertEqual(
      morphism.apply(on: factory.encode(family: [[1, 2], [1, 3]])),
      family)
  }

  func testBinaryUnion() {
    let family = factory.encode(family: [[4, 2], [1, 3], [3, 7]])
    let morphism = morphisms.union(morphisms.identity, morphisms.constant(family))

    XCTAssertEqual(morphism.apply(on: factory.zero), family)
    XCTAssertEqual(morphism.apply(on: factory.one), family.union([[]]))
    XCTAssertEqual(
      morphism.apply(on: factory.encode(family: [[1, 2], [1, 3]])),
      factory.encode(family: [[1, 2], [1, 3], [3, 7], [4, 2]]))
  }

  func testBinaryIntersection() {
    let family = factory.encode(family: [[4, 2], [1, 3], [3, 7]])
    let morphism = morphisms.intersection(morphisms.identity, morphisms.constant(family))

    XCTAssertEqual(morphism.apply(on: factory.zero), factory.zero)
    XCTAssertEqual(morphism.apply(on: factory.one), factory.zero)
    XCTAssertEqual(
      morphism.apply(on: factory.encode(family: [[1, 2], [1, 3]])),
      factory.encode(family: [[1, 3]]))
  }

  func testBinarySymmetricDifference() {
    let family = factory.encode(family: [[4, 2], [1, 3], [3, 7]])
    let morphism = morphisms.symmetricDifference(
      morphisms.identity,
      morphisms.constant(family))

    XCTAssertEqual(morphism.apply(on: factory.zero), family)
    XCTAssertEqual(morphism.apply(on: factory.one), family.union(factory.one))
    XCTAssertEqual(
      morphism.apply(on: factory.encode(family: [[1, 2], [1, 3]])),
      factory.encode(family: [[1, 2], [3, 7], [4, 2]]))
  }

  func testSubtraction() {
    let family = factory.encode(family: [[4, 2], [1, 3], [3, 7]])
    let morphism = morphisms.subtraction(morphisms.identity, morphisms.constant(family))

    XCTAssertEqual(morphism.apply(on: factory.zero), factory.zero)
    XCTAssertEqual(morphism.apply(on: factory.one), factory.one)
    XCTAssertEqual(
      morphism.apply(on: factory.encode(family: [[1, 2], [1, 3]])),
      factory.encode(family: [[1, 2]]))
  }

  func testComposition() {
    let family = factory.encode(family: [[4, 2], [1, 3], [3, 7]])
    let morphism = morphisms.composition(
      of: morphisms.identity,
      with: morphisms.constant(family))

    XCTAssertEqual(morphism.apply(on: factory.zero), family)
    XCTAssertEqual(morphism.apply(on: factory.one), family)
    XCTAssertEqual(
      morphism.apply(on: factory.encode(family: [[1, 2], [1, 3]])),
      family)
  }

  func testFixedPoint() {
    let i = morphisms.inductive(
      function: { [unowned self] this, pointer in
        return (
          take: self.morphisms.constant(self.factory.zero).apply(on:),
          skip: self.morphisms.identity.apply(on:))
      })
    let morphism = morphisms.fixedPoint(of: i)

    XCTAssertEqual(morphism.apply(on: factory.zero), factory.zero)
    XCTAssertEqual(morphism.apply(on: factory.one), factory.one)
    XCTAssertEqual(morphism.apply(on: factory.encode(family: [[1, 2], [2, 3]])), factory.zero)
  }

  func testInsert() {
    let morphism = morphisms.insert(keys: [2, 5])

    XCTAssertEqual(morphism.apply(on: factory.zero), factory.zero)
    XCTAssertEqual(morphism.apply(on: factory.one), factory.encode(family: [[2, 5]]))
    XCTAssertEqual(
      morphism.apply(on: factory.encode(family: [[1, 2], [1, 3]])),
      factory.encode(family: [[1, 2, 5], [1, 2, 3, 5]]))
  }

  func testRemove() {
    let morphism = morphisms.remove(keys: [2, 5])

    XCTAssertEqual(morphism.apply(on: factory.zero), factory.zero)
    XCTAssertEqual(morphism.apply(on: factory.one), factory.one)
    XCTAssertEqual(
      morphism.apply(on: factory.encode(family: [[1, 2], [1, 3]])),
      factory.encode(family: [[1], [1, 3]]))
  }

  func testInclusiveFilter() {
    let morphism = morphisms.filter(containing: [1, 2])

    XCTAssertEqual(morphism.apply(on: factory.zero), factory.zero)
    XCTAssertEqual(morphism.apply(on: factory.one), factory.zero)
    XCTAssertEqual(
      morphism.apply(on: factory.encode(family: [[1, 2], [1, 3]])),
      factory.encode(family: [[1, 2]]))
  }

  func testExclusiveFilter() {
    let morphism = morphisms.filter(excluding: [3, 4])

    XCTAssertEqual(morphism.apply(on: factory.zero), factory.zero)
    XCTAssertEqual(morphism.apply(on: factory.one), factory.one)
    XCTAssertEqual(
      morphism.apply(on: factory.encode(family: [[1, 2], [1, 3]])),
      factory.encode(family: [[1, 2]]))
  }

  func testMap() {
    let morphism = morphisms.map(transform: { x in x * x })

    XCTAssertEqual(morphism.apply(on: factory.zero), factory.zero)
    XCTAssertEqual(morphism.apply(on: factory.one), factory.one)
    XCTAssertEqual(
      morphism.apply(on: factory.encode(family: [[1, 2], [1, 3], [2, 3]])),
      factory.encode(family: [[1, 4], [1, 9], [4, 9]]))
  }

  func testInductive() {
    let morphism = morphisms.inductive(
      substitutingOneWith: factory.encode(family: [[Int.max]]),
      function: { [unowned self] this, pointer in
        let phi = self.morphisms.composition(
          of: this,
          with: self.morphisms.remove(keys: [pointer.pointee.key + 1]))
        return (take: phi.apply(on:), skip: phi.apply(on:))
      })

    XCTAssertEqual(morphism.apply(on: factory.zero), factory.zero)
    XCTAssertEqual(morphism.apply(on: factory.one), factory.encode(family: [[Int.max]]))
    XCTAssertEqual(
      morphism.apply(on: factory.encode(family: [[1, 2], [1, 3]])),
      factory.encode(family: [[1, Int.max], [1, 3, Int.max]]))
  }

}
