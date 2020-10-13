import XCTest
import DDKit

final class MorphismsTests: XCTestCase {

  let factory = MFDDFactory<Int, String>()

  var morphisms: MFDDMorphismFactory<Int, String> { factory.morphisms }

  func testIdentity() {
    let morphism = morphisms.identity

    XCTAssertEqual(morphism.apply(on: factory.zero), factory.zero)
    XCTAssertEqual(morphism.apply(on: factory.one), factory.one)
    XCTAssertEqual(
      morphism.apply(on: factory.encode(family: [[1: "a", 2: "b"], [1: "a", 3: "c"]])),
      factory.encode(family: [[1: "a", 2: "b"], [1: "a", 3: "c"]]))
  }

  func testConstant() {
    let family = factory.encode(family: [[4: "d", 2: "b"], [1: "a", 3: "c"], [3: "c", 7: "g"]])
    let morphism = morphisms.constant(family)

    XCTAssertEqual(morphism.apply(on: factory.zero), family)
    XCTAssertEqual(morphism.apply(on: factory.one), family)
    XCTAssertEqual(
      morphism.apply(on: factory.encode(family: [[1: "a", 2: "b"], [1: "a", 3: "c"]])),
      family)
  }

  func testBinaryUnion() {
    let family = factory.encode(family: [[4: "d", 2: "b"], [1: "a", 3: "c"]])
    let morphism = morphisms.union(morphisms.identity, morphisms.constant(family))

    XCTAssertEqual(morphism.apply(on: factory.zero), family)
    XCTAssertEqual(morphism.apply(on: factory.one), family.union([[]]))
    XCTAssertEqual(
      morphism.apply(on: factory.encode(family: [[1: "a", 2: "b"], [1: "a", 3: "c"]])),
      factory.encode(family: [[1: "a", 2: "b"], [1: "a", 3: "c"], [4: "d", 2: "b"]]))
  }

  func testBinaryIntersection() {
    let family = factory.encode(family: [[4: "d", 2: "b"], [1: "a", 3: "c"]])
    let morphism = morphisms.intersection(morphisms.identity, morphisms.constant(family))

    XCTAssertEqual(morphism.apply(on: factory.zero), factory.zero)
    XCTAssertEqual(morphism.apply(on: factory.one), factory.zero)
    XCTAssertEqual(
      morphism.apply(on: factory.encode(family: [[1: "a", 2: "b"], [1: "a", 3: "c"]])),
      factory.encode(family: [[1: "a", 3: "c"]]))
  }

  func testBinarySymmetricDifference() {
    let family = factory.encode(family: [[4: "d", 2: "b"], [1: "a", 3: "c"]])
    let morphism = morphisms.symmetricDifference(
      morphisms.identity,
      morphisms.constant(family))

    XCTAssertEqual(morphism.apply(on: factory.zero), family)
    XCTAssertEqual(morphism.apply(on: factory.one), family.union(factory.one))
    XCTAssertEqual(
      morphism.apply(on: factory.encode(family: [[1: "a", 2: "b"], [1: "a", 3: "c"]])),
      factory.encode(family: [[1: "a", 2: "b"], [4: "d", 2: "b"]]))
  }

  func testSubtraction() {
    let family = factory.encode(family: [[4: "d", 2: "b"], [1: "a", 3: "c"]])
    let morphism = morphisms.subtraction(morphisms.identity, morphisms.constant(family))

    XCTAssertEqual(morphism.apply(on: factory.zero), factory.zero)
    XCTAssertEqual(morphism.apply(on: factory.one), factory.one)
    XCTAssertEqual(
      morphism.apply(on: factory.encode(family: [[1: "a", 2: "b"], [1: "a", 3: "c"]])),
      factory.encode(family: [[1: "a", 2: "b"]]))
    XCTAssertEqual(
      morphism.apply(on: factory.encode(family: [[1: "a", 2: "b"], [1: "a", 3: "c"], [1: "a", 3: "d"]])),
      factory.encode(family: [[1: "a", 2: "b"], [1: "a", 3: "d"]]))
  }

  func testComposition() {
    let family = factory.encode(family: [[4: "d", 2: "b"], [1: "a", 3: "c"]])
    let morphism = morphisms.composition(
      of: morphisms.identity,
      with: morphisms.constant(family))

    XCTAssertEqual(morphism.apply(on: factory.zero), family)
    XCTAssertEqual(morphism.apply(on: factory.one), family)
    XCTAssertEqual(
      morphism.apply(on: factory.encode(family: [[1: "a", 2: "b"], [1: "a", 3: "c"]])),
      family)
  }

  func testFixedPoint() {
    let i = morphisms.inductive(
      function: { [unowned self] this, pointer in
        return (
          take: pointer.pointee.take
            .mapValues({ _ in self.morphisms.constant(self.factory.zero).apply(on:) }),
          skip: self.morphisms.identity.apply(on:))
      })
    let morphism = morphisms.fixedPoint(of: i)

    XCTAssertEqual(morphism.apply(on: factory.zero), factory.zero)
    XCTAssertEqual(morphism.apply(on: factory.one), factory.one)
    XCTAssertEqual(
      morphism.apply(on: factory.encode(family: [[1: "a", 2: "b"], [2: "b", 3: "c"]])),
      factory.zero)
  }

  func testInsert() {
    let morphism = morphisms.insert(assignments: [2: "b", 5: "e"])

    XCTAssertEqual(morphism.apply(on: factory.zero), factory.zero)
    XCTAssertEqual(morphism.apply(on: factory.one), factory.encode(family: [[2: "b", 5: "e"]]))
    XCTAssertEqual(
      morphism.apply(on: factory.encode(family: [[1: "a", 2: "b"], [1: "a", 3: "c"]])),
      factory.encode(family: [[1: "a", 2: "b", 5: "e"], [1: "a", 2: "b", 3: "c", 5: "e"]]))
  }

  func testExclusiveFilter() {
    let morphism = morphisms.filter(excluding: [(key: 3, values: ["c"]), (key: 4, values: ["d"])])

    XCTAssertEqual(morphism.apply(on: factory.zero), factory.zero)
    XCTAssertEqual(morphism.apply(on: factory.one), factory.one)
    XCTAssertEqual(
      morphism.apply(on: factory.encode(family: [[1: "a", 2: "b"], [1: "a", 3: "c"]])),
      factory.encode(family: [[1: "a", 2: "b"]]))
  }

}
